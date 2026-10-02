# SHABLON 0.1.0

First release of a small, Unicode-friendly string formatter for Eiffel.

## Highlights

- One `format` operation, available through inheritance or `{SHABLON}.format`.
  Pass values directly using tuple argument unfolding, or supply an explicit tuple.
- Automatic `{}` and zero-based numbered `{0}` fields, including reuse and reordering.
  Literal braces use `{{` and `}}`; inserted text is never parsed again.
- Unicode text with fresh `STRING_32` results and no mutation of caller inputs.
- A practical subset of Python's format specifications: decimal precision,
  comma or underscore grouping, width, alignment, custom fill, zero padding,
  explicit signs, and scientific notation (`e` and `E`).
- Exact integer formatting across all Eiffel integer sizes; floating-point rounding
  to nearest, ties to even, with signed zero, subnormal values, infinities and NaN.
- Formatting errors identify the category and template position, plus the argument
  index when applicable. Errors remain active with assertion checking disabled.

```eiffel
message := {SHABLON}.format ("Hello, {}! Total: {:,.2f}", "Alice", 12345.5)
-- Hello, Alice! Total: 12,345.50
```

## Installation and compatibility

Reference `shablon.ecf` from your application's ECF; see the [installation guide](../README.md#installation).
The library is void-safe and uses standard Eiffel classes, with no additional
runtime dependencies beyond the selected compiler's base library.

Local verification passed on macOS with EiffelStudio 25.02 and the installed Gobo:
23 tests and 334 assertions per run, with Eiffel assertions enabled and disabled.
CI passed for Gobo 26.06 and EiffelStudio on Linux, macOS and Windows,
including both assertion modes and the demo. Linux and Windows use EiffelStudio 25.12; macOS uses Homebrew's
available EiffelStudio version, reported in the build log.

## Scope

Automatic and numbered fields cannot be mixed. Width counts Unicode code points,
not terminal display columns. Byte strings containing UTF-8 must be decoded first.
Named fields, dynamic width or precision, alternate numeric bases, locale-dependent
formatting, `g`, string truncation and color are outside this release.

See the [grammar](grammar.md) for exact syntax, rounding and failure rules.

## License

Apache License 2.0. Copyright 2026 samedit66.
