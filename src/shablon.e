note

	description:
	"[
		Unicode string formatting with positional fields, escaped braces and numeric presentation.

		### Usage

		Inherit `SHABLON` to call `format` directly:

		```eiffel
		message := format ("Hello, {}!", "Alice")
		-- Hello, Alice!
		```

		Use a class call without inheritance:

		```eiffel
		message := {SHABLON}.format ("{1} invited {0}.", "Bob", "Alice")
		-- Alice invited Bob.
		```

		Add presentation options after a colon:

		```eiffel
		message := {SHABLON}.format ("Total: {:,.2f}", 12345.5)
		-- Total: 12,345.50
		```

		Values can be passed as ordinary arguments; EiffelStudio and Gobo collect them
		into the final tuple parameter. An explicit tuple is also accepted:

		```eiffel
		message := {SHABLON}.format ("Hello, {}!", ["Alice"])
		message := {SHABLON}.format ("No values needed.", [])
		```

		To format a tuple as one value, wrap it: `format ("{}", [tuple_value])`.
		Numbered fields are zero-based;
		automatic and numbered fields cannot be mixed in one template.
		Use `{{` and `}}` for literal braces. Each call returns a fresh `STRING_32`.
		Invalid fields, arguments or presentation options raise `SHABLON_FORMAT_ERROR`.
		]"
	author: "samedit66"
	email: "samedit66@yandex.ru"
	date: "2026-10-03"

class SHABLON

inherit {NONE}

	SHABLON_FIELD_PARSER
		export {NONE} all end

	SHABLON_VALUE_FORMATTER
		export {NONE} all end

	SHABLON_ERROR_HELPER
		export {NONE} all end

feature -- Formatting

	format (a_template: READABLE_STRING_GENERAL; a_arguments: TUPLE): STRING_32
			-- Return fresh text after processing fields and escapes from left to right.
			-- Field syntax and mode errors precede argument lookup; inserted text is never parsed.
		local
			i, j, colon, index_end, next_index, mode: INTEGER
			selection: like parsed_index
			spec: like parsed_specification
			c: CHARACTER_32
		do
			create Result.make (a_template.count)
			from
				i := 1
			until
				i > a_template.count
			loop
				c := a_template [i]
				if (c = '{' or c = '}') and then i < a_template.count and then a_template [i + 1] = c then
					Result.append_character (c)
					i := i + 2
				elseif c = '{' then
					colon := 0
					from
						j := i + 1
					until
						j > a_template.count or else a_template [j] = '}'
					loop
						if a_template [j] = ':' and colon = 0 then
							colon := j
						end
						j := j + 1
					end
					if j > a_template.count then
						fail ({SHABLON_FORMAT_ERROR}.invalid_field, i, -1)
					end
					index_end := j - 1
					if colon > 0 then
						index_end := colon - 1
					end
					selection := parsed_index (a_template, i + 1, index_end, i)
					spec := parsed_specification (a_template, colon, j - 1, i)
					if (selection.automatic and mode = 2) or (not selection.automatic and mode = 1) then
						fail ({SHABLON_FORMAT_ERROR}.mixed_field_modes, i, -1)
					end
					if selection.overflow then
						fail ({SHABLON_FORMAT_ERROR}.index_out_of_range, i, -1)
					end
					if selection.automatic then
						mode := 1
						selection.index := next_index
						next_index := next_index + 1
					else
						mode := 2
					end
					append_argument (Result, a_arguments, selection.index, i, spec)
					i := j + 1
				elseif c = '}' then
					fail ({SHABLON_FORMAT_ERROR}.unexpected_closing_brace, i, -1)
				else
					Result.append_character (c)
					i := i + 1
				end
			end
		ensure
			instance_free: class
		end

feature {NONE} -- Value rendering

	append_argument (output: STRING_32; arguments: TUPLE; index, position: INTEGER; spec: like parsed_specification)
			-- Append one selected value, or raise a missing/void argument error.
			-- Check the zero-based index before adding one, avoiding overflow at INTEGER_32.max_value.
		do
			if index >= arguments.count then
				fail ({SHABLON_FORMAT_ERROR}.missing_argument, position, index)
			elseif attached arguments [index + 1] as value then
				output.append (rendered_value (value, spec, position, index))
			else
				fail ({SHABLON_FORMAT_ERROR}.void_argument, position, index)
			end
		ensure
			instance_free: class
		end

end
