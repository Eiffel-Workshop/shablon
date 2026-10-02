<div align="center">

# shablon

[![ISE Eiffel](https://img.shields.io/badge/toolchain-ISE%20Eiffel-17365D)](https://www.eiffel.com/)
[![Gobo Eiffel](https://img.shields.io/badge/toolchain-Gobo%20Eiffel-8B5A2B)](https://www.gobosoft.com/)

[![CI](https://github.com/Eiffel-Workshop/shablon/actions/workflows/ci.yml/badge.svg)](https://github.com/Eiffel-Workshop/shablon/actions/workflows/ci.yml)

A small and friendly string formatter for Eiffel.

[Grammar](docs/grammar.md) · [API](src/shablon.e) · [Example](examples/demo/demo_application.e)

</div>

## Highlights

- Unicode-friendly: accepts 8-bit and 32-bit strings and returns `STRING_32`.
- Familiar `{}` placeholders and a practical subset of
  [Python's format specification mini-language](https://docs.python.org/3/library/string.html#format-specification-mini-language).
- Decimal precision, digit grouping, width, alignment, custom fill, zero padding,
  explicit signs, scientific notation, and much more.

## Usage

Just call `{SHABLON}.format`:

```eiffel
local
    message: STRING_32
do
    message := {SHABLON}.format ("Hello, {}!", "Alice")
        -- Hello, Alice!

    message := {SHABLON}.format ("{0} invited {1}; thanks, {0}!", "Alice", "Bob")
        -- Alice invited Bob; thanks, Alice!

    message := {SHABLON}.format ("Total: {:,.2f}", 12345.5)
        -- Total: 12,345.50
end
```

Inherit `SHABLON` to call `format` directly. Each call returns a fresh `STRING_32`.
See [SHABLON](src/shablon.e) for call styles and explicit tuples, and the
[grammar](docs/grammar.md) for formatting options and error rules.

## Installation

Clone the library into your application:

```sh
git clone https://github.com/Eiffel-Workshop/shablon.git vendor/shablon
```

Reference it from your application's ECF:

```xml
<library name="shablon" location="vendor/shablon/shablon.ecf" readonly="true"/>
```

Set `GOBO` to your Gobo installation and `GOBO_EIFFEL` to `ge` or `ise`.
The library is void-safe and uses standard Eiffel classes.

For development, run `just test` or `just example`; see the [justfile](justfile).

Licensed under [Apache License 2.0](LICENSE). Copyright 2026 samedit66.
