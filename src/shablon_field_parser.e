note

	description:

		"Interpret field indices and presentation options in a template, rejecting invalid syntax."

	author: "samedit66"
	email: "samedit66@yandex.ru"
	date: "2026-10-03"

class SHABLON_FIELD_PARSER

inherit {NONE}

	SHABLON_ERROR_HELPER
		export {NONE} all end

feature {SHABLON, SHABLON_VALUE_FORMATTER} -- Parsing

	parsed_index (text: READABLE_STRING_GENERAL; first, last, position: INTEGER): TUPLE [index: INTEGER; automatic, overflow: BOOLEAN]
			-- Parse an omitted or zero-based index without mutating the template.
			-- Finish checking syntax even after overflow so invalid syntax takes precedence.
			-- Selective export also protects static calls: Gobo checks the declaring feature's export.
		local
			i, digit, index: INTEGER
			invalid, overflow: BOOLEAN
			c: CHARACTER_32
		do
			if first > last then
				Result := [0, True, False]
			else
				invalid := last > first and then text [first] = '0'
				from
					i := first
				until
					i > last
				loop
					c := text [i]
					if c < '0' or c > '9' then
						invalid := True
					elseif not overflow then
						digit := c.code - ('0').code
						if index > ({INTEGER_32}.max_value - digit) // 10 then
							overflow := True
						else
							index := index * 10 + digit
						end
					end
					i := i + 1
				end
				if invalid then
					fail ({SHABLON_FORMAT_ERROR}.invalid_field, position, -1)
				end
				Result := [index, False, overflow]
			end
		ensure
			instance_free: class
		end

	parsed_specification (text: READABLE_STRING_GENERAL; colon, last, position: INTEGER): TUPLE [fill, alignment, sign, grouping, presentation: CHARACTER_32; width, precision: INTEGER; zero, explicit_fill: BOOLEAN]
			-- Parse presentation options into a fresh record with defaults for omitted options.
			-- CHARACTER_32 literals are explicit: ISE does not widen characters inside a tuple.
			-- Reserve integer capacity for exact binary64 digits when validating precision.
		local
			i, first: INTEGER
			c: CHARACTER_32
		do
			Result := [{CHARACTER_32} ' ', {CHARACTER_32} '%U', {CHARACTER_32} '%U', {CHARACTER_32} '%U', {CHARACTER_32} '%U', 0, -1, False, False]
			if colon > 0 then
				i := colon + 1
				if i < last and then is_alignment (text [i + 1]) then
					Result.fill := text [i]
					Result.explicit_fill := True
					Result.alignment := text [i + 1]
					if Result.fill = '{' or Result.fill = '}' then
						fail ({SHABLON_FORMAT_ERROR}.invalid_specification, position, -1)
					end
					i := i + 2
				elseif i <= last and then is_alignment (text [i]) then
					Result.alignment := text [i]
					i := i + 1
				end
				if i <= last then
					c := text [i]
					if c = '+' or c = '-' or c = ' ' then
						Result.sign := c
						i := i + 1
					end
				end
				if i <= last and then text [i] = '0' then
					Result.zero := True
					if not Result.explicit_fill then
						Result.fill := '0'
					end
					i := i + 1
				end
				first := i
				from
				until
					i > last or else not is_digit (text [i])
				loop
					i := i + 1
				end
				Result.width := parsed_size (text, first, i - 1, position)
				if i <= last and then (text [i] = ',' or text [i] = '_') then
					Result.grouping := text [i]
					i := i + 1
				end
				if i <= last and then text [i] = '.' then
					i := i + 1
					first := i
					from
					until
						i > last or else not is_digit (text [i])
					loop
						i := i + 1
					end
					if i = first then
						fail ({SHABLON_FORMAT_ERROR}.invalid_specification, position, -1)
					end
					Result.precision := parsed_size (text, first, i - 1, position)
				end
				if i <= last then
					c := text [i]
					if c = 'd' or c = 'f' or c = 'e' or c = 'E' then
						Result.presentation := c
						i := i + 1
					end
				end
				if i <= last or Result.precision > {INTEGER_32}.max_value - 1024 or (Result.precision >= 0 and Result.presentation /= 'f' and Result.presentation /= 'e' and Result.presentation /= 'E') then
					fail ({SHABLON_FORMAT_ERROR}.invalid_specification, position, -1)
				end
			end
		ensure
			instance_free: class
		end

feature {NONE} -- Parsing support

	parsed_size (text: READABLE_STRING_GENERAL; first, last, position: INTEGER): INTEGER
			-- Read ASCII digits as a nonnegative size, checking before each multiply and addition.
			-- An empty digit range denotes omitted width and produces zero.
		local
			i, digit: INTEGER
		do
			from
				i := first
			until
				i > last
			loop
				digit := text [i].code - ('0').code
				if Result > ({INTEGER_32}.max_value - digit) // 10 then
					fail ({SHABLON_FORMAT_ERROR}.invalid_specification, position, -1)
				end
				Result := Result * 10 + digit
				i := i + 1
			end
		ensure
			instance_free: class
		end

	is_digit (c: CHARACTER_32): BOOLEAN
			-- Is `c` an ASCII decimal digit? Unicode digit lookalikes are not accepted.
		do
			Result := c >= '0' and c <= '9'
		ensure
			instance_free: class
		end

	is_alignment (c: CHARACTER_32): BOOLEAN
			-- Is `c` one of the supported left, right, center or sign-aware alignments?
		do
			Result := c = '<' or c = '>' or c = '^' or c = '='
		ensure
			instance_free: class
		end

end
