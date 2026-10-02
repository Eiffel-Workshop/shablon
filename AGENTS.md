# SHABLON

A small, Unicode-friendly string formatting library for Eiffel. It provides one
`format` operation with positional fields and a practical subset of Python's
format specifications. Human-friendly usage takes priority over feature count.

## Stack and layout

- EiffelStudio and Gobo; void-safe Eiffel and standard ELKS classes.
- ECF configuration, Gobo `getest` tests, `just` recipes, Gobo `gedoc` formatting.
- `src/`: public `SHABLON` API, parsing, value rendering and formatting errors.
- `tests/`: behavior and diagnostic tests; `examples/demo/`: runnable usage.
- `docs/grammar.md`: syntax and behavior contract; `README.md`: minimal quick start.

## Library design

- Keep the API obvious: inherit `SHABLON` or call `{SHABLON}.format`.
- Prefer tuple argument unfolding in examples; retain explicit tuples when useful.
- Use familiar inline format specifications, not separate methods such as
  `decimal`, `grouped` or `zero_padded`.
- Keep helpers hidden through selective export and `inherit {NONE}` with
  `export {NONE} all`. Add a class only when it makes the implementation clearer.
- Preserve the documented grammar and error behavior. Discuss scope or public
  contract changes before implementing them. Color is outside the current scope.
- Avoid speculative abstractions and new runtime dependencies.

## Code requirements

- Keep code simple; extract shared logic into focused features.
- Follow Design by Contract, command-query separation and established Eiffel style.
- Return a fresh `STRING_32`; never mutate or retain caller-owned inputs or introduce
  shared mutable formatting state. Do not interpret UTF-8 bytes as decoded text.
- Raise explicit formatting errors even when assertion checking is disabled.
- Keep both compiler targets working; do not claim platform support without testing it.
- Document every feature in English, including nontrivial algorithms and compiler
  workarounds. Class descriptions explain purpose, not implementation mechanics;
  preserve author metadata and public API examples.
- Use typed `getest` assertions that report expected and actual values. For Unicode
  comparisons, preserve the existing UTF-8 conversion rather than narrowing text.
- Keep README concise; put detailed rules in documentation or class comments.

## Verification

Set `GOBO` to the Gobo installation and put EiffelStudio's `ec` on `PATH`.

- `just format`: format Eiffel sources.
- `just test`: test both compilers with assertions enabled and disabled.
- `just example-gobo` and `just example-ise`: verify changed examples.
- `git diff --check`: check whitespace before committing.

For code changes, run the relevant checks and report unavailable toolchains.
For documentation-only changes, check links and examples without unnecessary rebuilds.
Use Conventional Commits and separate commits by area when committing is requested.
