class SHABLON

feature -- Formatting

	format (a_template: READABLE_STRING_GENERAL; a_arguments: TUPLE): STRING_32
			-- New text with fields replaced by their corresponding arguments.
			-- Automatic fields and zero-based numbered fields cannot be mixed.
		local
			i, j, field_start, field_index, next_index, mode, digit: INTEGER
			c: CHARACTER_32
			is_automatic, invalid_index, index_overflow: BOOLEAN
		do
			create Result.make (a_template.count)
			from
				i := 1
			until
				i > a_template.count
			loop
				c := a_template [i]
				if c = '{' then
					if i < a_template.count and then a_template [i + 1] = '{' then
						Result.append_character ('{')
						i := i + 2
					else
						field_start := i
						i := i + 1
						from
							j := i
						until
							j > a_template.count or else a_template [j] = '}'
						loop
							j := j + 1
						end
						if j > a_template.count then
							fail ({SHABLON_FORMAT_ERROR}.invalid_field, field_start, -1)
						end
						is_automatic := j = i
						field_index := 0
						invalid_index := False
						index_overflow := False
						if is_automatic then
							field_index := next_index
						else
							invalid_index := j - i > 1 and then a_template [i] = '0'
							from
							until
								i >= j
							loop
								c := a_template [i]
								if c < '0' or c > '9' then
									invalid_index := True
								elseif not index_overflow then
									digit := c.code - ('0').code
									if field_index > ({INTEGER_32}.max_value - digit) // 10 then
										index_overflow := True
									else
										field_index := field_index * 10 + digit
									end
								end
								i := i + 1
							end
						end
						if invalid_index then
							fail ({SHABLON_FORMAT_ERROR}.invalid_field, field_start, -1)
						end
						if (is_automatic and mode = 2) or (not is_automatic and mode = 1) then
							fail ({SHABLON_FORMAT_ERROR}.mixed_field_modes, field_start, -1)
						end
						if index_overflow then
							fail ({SHABLON_FORMAT_ERROR}.index_out_of_range, field_start, -1)
						end
						if is_automatic then
							mode := 1
						else
							mode := 2
						end
						append_argument (Result, a_arguments, field_index, field_start)
						if is_automatic then
							next_index := next_index + 1
						end
						i := j + 1
					end
				elseif c = '}' then
					if i < a_template.count and then a_template [i + 1] = '}' then
						Result.append_character ('}')
						i := i + 2
					else
						fail ({SHABLON_FORMAT_ERROR}.unexpected_closing_brace, i, -1)
					end
				else
					Result.append_character (c)
					i := i + 1
				end
			end
		ensure
			instance_free: class
		end

feature {NONE} -- Implementation

	append_argument (a_result: STRING_32; a_arguments: TUPLE; a_index, a_position: INTEGER)
			-- Append the selected argument, checking the index before adding one.
		do
			if a_index >= a_arguments.count then
				fail ({SHABLON_FORMAT_ERROR}.missing_argument, a_position, a_index)
			elseif attached a_arguments [a_index + 1] as value then
				append_value (a_result, value)
			else
				fail ({SHABLON_FORMAT_ERROR}.void_argument, a_position, a_index)
			end
		ensure
			instance_free: class
		end

	append_value (a_result: STRING_32; a_value: separate ANY)
			-- Append strings as text and other values through `out'.
		local
			text: STRING_8
		do
			if attached {READABLE_STRING_GENERAL} a_value as string then
				a_result.append_string_general (string)
			elseif attached {separate READABLE_STRING_GENERAL} a_value as string then
				a_result.append (create {STRING_32}.make_from_separate (string))
			else
				create text.make_from_separate (a_value.out)
				a_result.append_string_general (text)
			end
		ensure
			instance_free: class
		end

	fail (a_category: READABLE_STRING_8; a_position, a_index: INTEGER)
			-- Raise a formatting error at `a_position'.
		local
			error: SHABLON_FORMAT_ERROR
		do
			create error.make (a_category, a_position, a_index)
			error.raise
		ensure
			instance_free: class
		end

end
