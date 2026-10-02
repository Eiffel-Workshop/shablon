# SHABLON: a small, predictable string formatter

Status: implemented. The examples below are covered by the executable test suite.

## Start with a sentence

Write the message as you want to read it. Use `{}` where a value belongs, and pass
the values in the same order:

```eiffel
message := {SHABLON}.format ("Hello, {}!", [name])
message := {SHABLON}.format ("{} has {} messages.", [name, count])
```

The public signature is:

```eiffel
format (a_template: READABLE_STRING_GENERAL; a_arguments: TUPLE): STRING_32
```

There is one operation, named `format`. It returns a new string. The caller decides
whether to display it, store it, or pass it to another routine.

## Choose the call style that fits the client

Use a class call for occasional formatting:

```eiffel
message := {SHABLON}.format ("Hello, {}!", [name])
```

Inherit `SHABLON` when formatting is common in a class:

```eiffel
class GREETER

inherit

    SHABLON

feature -- Access

    greeting (a_name: READABLE_STRING_GENERAL): STRING_32
        do
            Result := format ("Hello, {}!", [a_name])
        end

end
```

Both call styles have the same meaning. Neither requires initialization or
configuration. Explicit tuples are the documented argument form: `[name]`,
`[name, count]`, or `[]`. Compiler-specific tuple argument unfolding is not required
to use the library.

## Reuse or reorder a value

Use numbered fields when the order in the sentence differs from the argument order
or a value appears more than once:

```eiffel
{SHABLON}.format ("{1}, {0}", ["Alice", "Bob"])
-- "Bob, Alice"

{SHABLON}.format ("{0} invited {1}; thank you, {0}!", ["Alice", "Bob"])
-- "Alice invited Bob; thank you, Alice!"
```

Field numbers start at zero. `{0}` refers to the first tuple item, which Eiffel
accesses at index 1. Automatic and numbered fields cannot be mixed in one template.
For ordinary messages, prefer `{}` so there are no indices to maintain.

## Keep braces literal

Double a brace to include it in the message:

```eiffel
{SHABLON}.format ("Value: {{{}}}", [42])
-- "Value: {42}"
```

Only the template is parsed. A brace inside an argument is ordinary text:

```eiffel
{SHABLON}.format ("Received: {}", ["{name}"])
-- "Received: {name}"
```

## Let values own their presentation

String arguments are inserted as text, including 32-bit strings. Other attached
values use their existing Eiffel `out` representation. Numbers can therefore be
passed directly without cells or formatting wrappers:

```eiffel
{SHABLON}.format ("Processed {} items.", [42])
-- "Processed 42 items."
```

When a value needs a particular representation, prepare that value before calling
SHABLON. For example, obtain `amount_text` from an existing number formatter and use:

```eiffel
message := {SHABLON}.format ("Total: {}", [amount_text])
```

This keeps the sentence readable and leaves rounding, precision, dates, currencies,
and locale rules with the code that knows what the value means. SHABLON does not
introduce a numeric formatting language. Its grammar has no `:d`, `:.2f`, or other
presentation specifications.

For domain objects, passing the intended display string is often clearer than
relying on the object's default `out`. SHABLON does not inspect object fields or
evaluate expressions written inside a template.

## Predictable boundary behavior

- Empty templates, empty tuples, and empty results are valid.
- Unused arguments are allowed. Every referenced argument must exist and be attached.
- A malformed template or invalid reference produces a formatting error; fields
  never silently disappear or remain unresolved.
- Diagnostics identify the error and its position in the template, with the field
  index when relevant. Position numbers start at 1.
- Error handling remains active when Eiffel assertion checking is disabled.
- The result is a fresh `STRING_32`; SHABLON does not modify or retain its inputs.
- SHABLON has no shared mutable formatting state. A custom `out` routine remains
  responsible for its own behavior and effects.

`READABLE_STRING_8` inputs are interpreted by their character codes. Encoded UTF-8
bytes must be decoded before formatting; SHABLON does not guess encodings. Console
encoding is the responsibility of the output layer.

The exact syntax and failure rules are defined in [the grammar](docs/grammar.md).

## What makes this library useful

The advantage is a small API whose ordinary use needs only a sentence and
a tuple. It combines automatic substitution, explicit reuse, Unicode text, and
actionable diagnostics without requiring a formatting object's mutable settings.

EiffelStudio already provides tuple-based substitution and Unicode formatting.
Gobo already provides extensive numeric formatting. SHABLON's goal is to make
everyday message construction convenient; it does not claim better numeric
algorithms or faster execution.

The implementation should remain usable with EiffelStudio and Gobo. Windows,
Linux, and macOS support must be verified in CI before being advertised as tested.

## Run the tests and example

Set `GOBO` to the Gobo installation directory and put EiffelStudio's `ec` on `PATH`.
The project uses the existing Gobo `getest` test framework; no additional runtime
library is required.

```sh
just test                      # Both compilers, assertions enabled and disabled
just test-gobo                 # Gobo, assertions enabled
just test-ise                  # EiffelStudio, assertions enabled
just test-gobo-no-assertions
just test-ise-no-assertions
just example-gobo
just example-ise
just format                    # Format Eiffel sources with Gobo gedoc
```

The suite covers both call styles, repeated and reordered values, brace escaping,
inserted braces, empty and Unicode text, native `out` representations, custom `out`
ordering and exceptions, result ownership, all error categories, and index overflow.
Each test run probes a precondition to verify the requested assertion mode.

Local verification uses Gobo and EiffelStudio 25.02 on macOS. The installed Gobo
compiler has a known ECF reader defect: the `check` assertion option sets the
invariant flag instead of the check flag. The mode probe therefore uses a
precondition. Formatting errors use explicit exceptions and remain tested in both
modes. Windows and Linux runs are still required before release.

The initial release keeps this one-call model. Additional syntax or public methods
should be justified by a concrete usage example that the existing API handles
poorly. Color is outside the current scope.
