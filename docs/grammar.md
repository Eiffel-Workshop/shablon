# Template grammar

Status: implemented contract. See [the usage guide](../README.md) for examples and scope.

## Syntax

The following EBNF defines the entire template language. Double quotes denote
literal characters; braces outside quotes denote repetition.

```ebnf
template        = { part } ;
part            = literal | escaped_open | escaped_close | field ;
literal         = character_except_braces ;
escaped_open    = "{{" ;
escaped_close   = "}}" ;
field           = automatic_field | numbered_field ;
automatic_field = "{}" ;
numbered_field  = "{", index, "}" ;
index           = "0" | nonzero_digit, { digit } ;
digit           = "0" | nonzero_digit ;
nonzero_digit   = "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
```

`character_except_braces` is any character from the input text other than `{` and
`}`. Digits in indices are ASCII digits. Whitespace is literal outside fields and
is not allowed inside fields. Leading zeros are not allowed except for index `0`.

At each position, doubled opening or closing braces are consumed as escapes.
Otherwise an opening brace begins a field; an unmatched closing brace is an error.
Escapes emit one literal brace and do not consume an argument.

## Argument selection

A template has one field mode:

- **Automatic:** each `{}` selects the next argument, starting with tuple item 1.
- **Numbered:** `{n}` selects tuple item `n + 1`; repetition and reordering are valid.
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
this specification adds no rounding or locale policy.

## Formatting errors

The failure channel is `SHABLON_FORMAT_ERROR`, inheriting `DEVELOPER_EXCEPTION`.
It exposes `category: IMMUTABLE_STRING_8`, `position: INTEGER`,
`field_index: INTEGER`, and `has_field_index: BOOLEAN`, plus a readable `description`.
The position counts characters in the original template, starting at one.
Missing-argument and void-argument errors contain the zero-based field index.
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

Scan and process the template from left to right. Report the first encountered
formatting error. Within a field, check syntax, then mode, then index range, then
argument availability and attachment. Thus an overflowing index containing a letter
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
| `{:d}` | `[42]` | `invalid_field` |
| `{` | `[]` | `invalid_field` |
| `}` | `[]` | `unexpected_closing_brace` |
