# Template grammar

Status: implemented contract. See the [quick start](../README.md) for installation and examples, or
[SHABLON](../src/shablon.e) for the public API.

## Syntax

The following EBNF defines the entire template language. Double quotes denote
literal characters; braces outside quotes denote repetition.

```ebnf
template        = { part } ;
part            = literal | escaped_open | escaped_close | field ;
literal         = character_except_braces ;
escaped_open    = "{{" ;
escaped_close   = "}}" ;
field           = "{", [ index ], [ ":", specification ], "}" ;
index           = "0" | nonzero_digit, { digit } ;
specification   = [ alignment_spec ], [ sign ], [ "0" ], [ width ],
                  [ grouping ], [ ".", precision ], [ presentation ] ;
alignment_spec  = [ fill ], alignment ;
alignment       = "<" | ">" | "^" | "=" ;
sign            = "+" | "-" | " " ;
grouping        = "," | "_" ;
presentation    = "d" | "f" | "e" | "E" ;
width           = digit, { digit } ;
precision       = digit, { digit } ;
digit           = "0" | nonzero_digit ;
nonzero_digit   = "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
```

`character_except_braces` is any character from the input text other than `{` and
`}`. Digits in indices are ASCII digits. Whitespace is literal outside fields and
is allowed inside a specification only as a sign or fill character. Leading zeros
are not allowed in argument indices except for index `0`. Width and precision are
nonnegative decimal integers. `fill` is one Unicode code point other than a brace;
it is recognized only when immediately followed by an alignment character.
Specifications cannot contain nested replacement fields.

At each position, doubled opening or closing braces are consumed as escapes.
Otherwise an opening brace begins a field; an unmatched closing brace is an error.
Escapes emit one literal brace and do not consume an argument.

## Argument selection

The `format` signature takes a template and a `TUPLE`. EiffelStudio and Gobo
support tuple argument unfolding, so `format ("{} / {}", first, second)` is
equivalent to `format ("{} / {}", [first, second])`. An existing tuple can be
passed directly as the argument collection. Use `[]` for an explicit empty collection.

A template has one field mode:

- **Automatic:** an omitted index, as in `{}` or `{:.2f}`, selects the next argument,
  starting with tuple item 1.
- **Numbered:** index `n`, as in `{n}` or `{n:.2f}`, selects tuple item `n + 1`;
  repetition and reordering are valid.
- **No fields:** the template contains only literal text and brace escapes.

A template containing both automatic and numbered fields is invalid. Brace escapes
do not affect the mode.

The supported index range is `0..2147483647` (`INTEGER_32.max_value`). The parser
detects larger values before arithmetic overflow. A representable index that does
not select a tuple item is a missing-argument error; even the largest supported
index is checked before adding one for tuple access.

Only selected arguments are required to exist and be attached. Unused tuple items
are ignored, including unused void items. A tuple passed as an argument collection
is not recursively expanded. To insert a tuple as one value, pass `[tuple_value]`.

## Value rendering

1. Insert a selected `READABLE_STRING_GENERAL` value directly as text.
2. For any other selected attached value, insert the text returned by its Eiffel
   `out` routine.
3. Do not parse the inserted text or interpret braces inside it.

For numbered fields, a repeated value is rendered once per occurrence, in template
order. SHABLON does not cache custom `out` results. A failure raised by a custom
`out` routine propagates; it is not relabeled as an invalid-template error.

The result contains literal and rendered text in template order. It is a new
`STRING_32`. Default numeric and Boolean representations follow Eiffel `out`;
fields without presentation settings preserve the native `out` representation.

## Presentation specifications

Specifications use a documented subset of Python conventions; this is not a promise
of compatibility with every Python or C++ format option.

- `d` accepts `INTEGER_8/16/32/64` and `NATURAL_8/16/32/64`.
- `f`, `e`, and `E` accept those integers and `REAL_32/64`. Integer values retain
  their exact magnitude, even beyond the exact integer range of `REAL_64`.
- `f` emits fixed notation. `e` and `E` emit one mantissa digit before the decimal
  point, then the requested fractional digits, then a signed exponent with at
  least two digits. The zero exponent is `+00`.
- Precision specifies fractional digits and defaults to six for `f/e/E`. It is
  invalid without one of those presentation types. Precision zero omits the point.
- Finite real values are rounded to nearest, ties to even, from their exact binary
  value. Carry from rounding can change the scientific exponent. Signed zero and
  negative values rounding to zero retain their minus sign.
- Explicit `f/e` render nonfinite values as `inf`, `-inf`, or `nan`; `E` uses uppercase.
  Precision does not add fractional digits to these values.
- `+` shows a sign for all numbers; a space shows a space for nonnegative numbers;
  `-` is the ordinary negative-only policy. Booleans are not numeric arguments.
- `,` and `_` group the integral digits by threes, including leading zeros used
  for sign-aware zero padding. They do not group fractional or exponent digits.
- Width is a minimum measured in Unicode code points. It includes the sign,
  decimal point, exponent, and separators. Values are never truncated.
- `<`, `>`, and `^` align left, right, and center. An odd extra fill character goes
  on the right when centering. Default alignment is right for numbers, left for
  strings and custom `out` text. The default fill is a space.
- `=` fills between a number's sign and digits. The `0` flag selects zero fill
  unless an explicit fill was supplied; without explicit alignment it selects `=`.
  Thus `{:06d}` formats `-42` as `-00042`, while `{:0>6d}` produces `000-42`.
- Sign-aware zero padding groups the added zeros too. Choose the smallest number
  of zeros that reaches the minimum width after grouping; a separator may make
  the final result exceed that width. `{:08,d}` formats `1234` as `0,001,234`.
- The `0` flag does not zero-pad infinities or NaN. Explicit custom fills remain
  ordinary text alignment.
- Non-numeric arguments allow width, custom fill, and `<`, `>`, `^` alignment.
  Numeric presentations, explicit signs, grouping, the `0` flag, and `=` are errors.

Index, width, and precision parsing detects integer overflow. Width and precision
must fit `INTEGER_32`; output sizing must also fit the string implementation's
integer capacity. Formatting can still fail if memory allocation cannot be satisfied.
Precision is limited to `INTEGER_32.max_value - 1024` to leave room for the number
and its presentation. Very large widths or precisions may require substantial memory.

Locale-based formatting, dynamic width or precision, named fields, alternate bases,
`g`, string truncation, and custom format-specification protocols are outside this
subset.

## Formatting errors

The failure channel is `SHABLON_FORMAT_ERROR`, inheriting `DEVELOPER_EXCEPTION`.
It exposes `category: IMMUTABLE_STRING_8`, `position: INTEGER`,
`field_index: INTEGER`, and `has_field_index: BOOLEAN`, plus a readable `description`.
The position counts characters in the original template, starting at one.
Missing-argument and void-argument errors contain the zero-based field index.
`incompatible_format` also identifies the selected argument.
Other categories use `field_index = -1` and `has_field_index = False`.

Category identifiers below are also available as class features of
`SHABLON_FORMAT_ERROR`.

| Category | Condition | Position |
| --- | --- | --- |
| `invalid_field` | A field has an invalid body or is unfinished | Opening brace |
| `unexpected_closing_brace` | A closing brace is neither escaped nor part of a field | Closing brace |
| `mixed_field_modes` | A field changes from automatic to numbered mode or vice versa | Opening brace of the conflicting field |
| `index_out_of_range` | The index exceeds the supported index range | Opening brace |
| `missing_argument` | A valid field selects an item outside the tuple | Opening brace |
| `void_argument` | A selected tuple item is void | Opening brace |
| `invalid_specification` | Specification syntax or size is unsupported | Opening brace |
| `incompatible_format` | The selected value cannot use the specification | Opening brace |

Scan and process the template from left to right. Report the first encountered
formatting error. Within a field, check syntax, then mode, then index range, then
argument availability and attachment, then presentation compatibility. Thus an overflowing index containing a letter
is an `invalid_field`; a valid digit sequence switching modes is a
`mixed_field_modes` error even if its value exceeds the supported range.
No partial result is returned. These rules do not depend on enabled assertions.

## Examples

| Template | Arguments | Result or error |
| --- | --- | --- |
| `Hello, {}!` | `["Alice"]` | `Hello, Alice!` |
| `{1}/{0}/{1}` | `["a", "b"]` | `b/a/b` |
| `{{{0}}}` | `[42]` | `{42}` |
| `{{}}` | `[]` | `{}` |
| `{}` | `["{0}"]` | `{0}` |
| Empty text | `[]` | Empty text |
| `Hello` | `[42]` | `Hello` |
| `{0}` | `[]` | `missing_argument` |
| `{} {0}` | `["a"]` | Mixed field modes at position 4 |
| `{01}` | `["a", "b"]` | `invalid_field` |
| `{name}` | `["Alice"]` | `invalid_field` |
| `{:d}` | `[42]` | `42` |
| `{:.2f}` | `[12.5]` | `12.50` |
| `{:.2e}` | `[12345.0]` | `1.23e+04` |
| `{:06d}` | `[-42]` | `-00042` |
| `{:q}` | `[42]` | `invalid_specification` |
| `{:.2f}` | `["12.5"]` | `incompatible_format` |
| `{` | `[]` | `invalid_field` |
| `}` | `[]` | `unexpected_closing_brace` |
