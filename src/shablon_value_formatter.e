note

	description:

		"Turn a value into text with the requested precision, grouping, sign, padding and alignment."

	author: "samedit66"
	email: "samedit66@yandex.ru"
	date: "2026-10-03"

class SHABLON_VALUE_FORMATTER

inherit {NONE}

	SHABLON_ERROR_HELPER
		export {NONE} all end

feature {SHABLON} -- Formatting

	rendered_value (value: separate ANY; spec: like {SHABLON_FIELD_PARSER}.parsed_specification; position, index: INTEGER): STRING_32
			-- Validate the specification against the value type and return fresh presented text.
			-- Preserve native out for default fields; integer f/e formatting never narrows to REAL_64.
		local
			text: STRING_32
			number: REAL_64
			numeric, integer, negative, special: BOOLEAN
			decimal: like exact_decimal
			precision: INTEGER
		do
			integer := is_integer (value)
			if attached {separate REAL_64_REF} value as real then
				number := real.item
				numeric := True
			elseif attached {separate REAL_32_REF} value as real then
				number := real.item.to_double
				numeric := True
			end
			numeric := numeric or integer
			if not numeric and (spec.presentation /= '%U' or spec.sign /= '%U' or spec.grouping /= '%U' or spec.zero or spec.alignment = '=') then
				fail ({SHABLON_FORMAT_ERROR}.incompatible_format, position, index)
			end
			if spec.presentation = 'd' and not integer then
				fail ({SHABLON_FORMAT_ERROR}.incompatible_format, position, index)
			end
			text := value_text (value)
			if numeric then
				negative := text.count > 0 and then text [1] = '-'
				if negative then
					text.remove_head (1)
				end
				if not integer then
					special := number.is_nan or number.is_negative_infinity or number.is_positive_infinity
					if special and spec.presentation /= '%U' then
						if number.is_nan then
							text := "nan"
						else
							text := "inf"
						end
						if spec.presentation = 'E' then
							text.to_upper
						end
					end
				end
				if not special and (spec.presentation = 'f' or spec.presentation = 'e' or spec.presentation = 'E') then
					if integer then
						decimal := [text, 0]
					else
						decimal := exact_decimal (number.abs)
					end
					precision := spec.precision
					if precision < 0 then
						precision := 6
					end
					if spec.presentation = 'f' then
						text := fixed_decimal (decimal.digits, decimal.scale, precision)
					else
						text := scientific_decimal (decimal.digits, decimal.scale, precision, spec.presentation)
					end
				end
				text := decorated_number (text, negative, special, spec)
			end
			Result := aligned_text (text, spec, numeric, special)
		ensure
			instance_free: class
		end

feature {NONE} -- Value access

	value_text (value: separate ANY): STRING_32
			-- Copy strings as Unicode text; copy other values from their out representation.
			-- Separate results are copied under a controlled argument for Gobo/ISE SCOOP typing.
		do
			if attached {READABLE_STRING_GENERAL} value as text then
				create Result.make_from_string_general (text)
			elseif attached {separate READABLE_STRING_GENERAL} value as text then
				create Result.make_from_separate (text)
			else
				create Result.make_from_string_general (create {STRING_8}.make_from_separate (value.out))
			end
		ensure
			instance_free: class
		end

	is_integer (value: separate ANY): BOOLEAN
			-- Is `value` one of the signed or unsigned integer reference families?
			-- Booleans, characters and numeric-looking strings do not qualify.
		do
			Result := attached {separate INTEGER_8_REF} value or attached {separate INTEGER_16_REF} value or attached {separate INTEGER_32_REF} value or attached {separate INTEGER_64_REF} value or attached {separate NATURAL_8_REF} value or attached {separate NATURAL_16_REF} value or attached {separate NATURAL_32_REF} value or attached {separate NATURAL_64_REF} value
		ensure
			instance_free: class
		end

feature {NONE} -- Exact decimal conversion

	exact_decimal (value: REAL_64): TUPLE [digits: STRING_32; scale: INTEGER]
			-- Return exact digits and decimal scale for a finite nonnegative binary real.
			-- Normalize with powers of two to recover the 53-bit mantissa, including subnormals.
			-- For a negative binary exponent multiply by powers of five: m*2^-n = m*5^n*10^-n.
			-- All later rounding operates on decimal digits; native out is not used as an approximation.
		require
			finite_nonnegative: value >= 0 and not value.is_positive_infinity
		local
			normalized: REAL_64
			mantissa: INTEGER_64
			exponent, scale: INTEGER
			digits: STRING_32
		do
			if value = 0 then
				Result := [create {STRING_32}.make_from_string ("0"), 0]
			else
				normalized := value
				exponent := -52
				from
				until
					normalized >= 1
				loop
					normalized := normalized * 2
					exponent := exponent - 1
				end
				from
				until
					normalized < 2
				loop
					normalized := normalized / 2
					exponent := exponent + 1
				end
				mantissa := (normalized * 4503599627370496.0).truncated_to_integer_64
				from
				until
					exponent >= 0 or else mantissa \\ 2 /= 0
				loop
					mantissa := mantissa // 2
					exponent := exponent + 1
				end
				create digits.make_from_string_general (mantissa.out)
				if exponent < 0 then
					scale := -exponent
					from
					until
						exponent = 0
					loop
						multiply_digits (digits, 5)
						exponent := exponent + 1
					end
				else
					from
					until
						exponent = 0
					loop
						multiply_digits (digits, 2)
						exponent := exponent - 1
					end
				end
				Result := [digits, scale]
			end
		ensure
			instance_free: class
		end

	multiply_digits (digits: STRING_32; factor: INTEGER)
			-- Multiply an owned decimal coefficient by a small positive factor in place.
			-- Propagate carry right to left; only factors two and five are needed.
		local
			i, product, carry: INTEGER
		do
			from
				i := digits.count
			until
				i = 0
			loop
				product := (digits [i].code - ('0').code) * factor + carry
				digits.put (('0').plus (product \\ 10), i)
				carry := product // 10
				i := i - 1
			end
			if carry > 0 then
				digits.prepend_string_general (carry.out)
			end
		ensure
			instance_free: class
		end

	rounded_digits (digits: STRING_32; removed: INTEGER): STRING_32
			-- Return a rounded coefficient after removing `removed` decimal digits.
			-- Round to nearest, ties to even; negative removal appends zeros without rounding.
		local
			kept, i: INTEGER
			up, tail_nonzero: BOOLEAN
			first_removed: CHARACTER_32
		do
			kept := digits.count - removed
			if removed <= 0 then
				Result := digits.twin
				append_fill (Result, '0', -removed)
			elseif kept < 0 then
				Result := "0"
			else
				if kept = 0 then
					Result := "0"
				else
					Result := digits.substring (1, kept)
				end
				first_removed := digits [kept + 1]
				from
					i := kept + 2
				until
					i > digits.count
				loop
					tail_nonzero := tail_nonzero or digits [i] /= '0'
					i := i + 1
				end
				up := first_removed > '5' or (first_removed = '5' and (tail_nonzero or (Result [Result.count].code - ('0').code) \\ 2 = 1))
				if up then
					increment_digits (Result)
				end
			end
		ensure
			instance_free: class
		end

	increment_digits (digits: STRING_32)
			-- Increment an owned decimal coefficient in place, carrying through trailing nines.
		local
			i: INTEGER
		do
			from
				i := digits.count
			until
				i = 0 or else digits [i] /= '9'
			loop
				digits.put ('0', i)
				i := i - 1
			end
			if i = 0 then
				digits.prepend_character ('1')
			else
				digits.put (digits [i].plus (1), i)
			end
		ensure
			instance_free: class
		end

	fixed_decimal (digits: STRING_32; scale, precision: INTEGER): STRING_32
			-- Return fixed notation with exactly `precision` fractional digits, rounded once.
			-- Add a leading zero for fractions and omit the decimal point at precision zero.
		local
			rounded: STRING_32
		do
			rounded := rounded_digits (digits, scale - precision)
			create Result.make (rounded.count.max (precision + 1) + 1)
			append_fill (Result, '0', precision + 1 - rounded.count)
			Result.append (rounded)
			if precision > 0 then
				Result.insert_character ('.', Result.count - precision + 1)
			end
		ensure
			instance_free: class
		end

	scientific_decimal (digits: STRING_32; scale, precision: INTEGER; marker: CHARACTER_32): STRING_32
			-- Return a rounded mantissa and a signed exponent with at least two digits.
			-- A carry expanding the mantissa increases the exponent; zero uses exponent zero.
		local
			rounded, exponent_text: STRING_32
			exponent: INTEGER
		do
			if digits.same_string ("0") then
				exponent := 0
			else
				exponent := digits.count - scale - 1
			end
			rounded := rounded_digits (digits, digits.count - precision - 1)
			if rounded.count > precision + 1 then
				rounded.remove_tail (1)
				exponent := exponent + 1
			end
			if precision > 0 then
				rounded.insert_character ('.', 2)
			end
			Result := rounded
			Result.append_character (marker)
			if exponent < 0 then
				Result.append_character ('-')
			else
				Result.append_character ('+')
			end
			create exponent_text.make_from_string_general (exponent.abs.out)
			append_fill (Result, '0', 2 - exponent_text.count)
			Result.append (exponent_text)
		ensure
			instance_free: class
		end

feature {NONE} -- Signs, grouping and alignment

	decorated_number (body: STRING_32; negative, special: BOOLEAN; spec: like {SHABLON_FIELD_PARSER}.parsed_specification): STRING_32
			-- Apply a sign, integral grouping and sign-aware padding to a fresh numeric body.
			-- Binary search finds the fewest leading zeros whose grouped length reaches the width.
			-- Grouping includes those zeros, so inserting a separator can exceed the minimum width.
		local
			sign, integral, tail: STRING_32
			split, i, zero_count, low, high, middle, available: INTEGER
			sign_padding: BOOLEAN
		do
			sign := ""
			if negative then
				sign := "-"
			elseif spec.sign = '+' then
				sign := "+"
			elseif spec.sign = ' ' then
				sign := " "
			end
			split := body.count + 1
			from
				i := 1
			until
				i > body.count
			loop
				if body [i] = '.' or body [i] = 'e' or body [i] = 'E' then
					split := i
					i := body.count
				end
				i := i + 1
			end
			integral := body.substring (1, split - 1)
			tail := body.substring (split, body.count)
			sign_padding := spec.alignment = '=' or (spec.alignment = '%U' and spec.zero)
			if sign_padding and not special then
				available := spec.width - sign.count - tail.count
				if spec.fill = '0' then
					low := 0
					high := (available - integral.count).max (0)
					from
					until
						low >= high
					loop
						middle := low + (high - low) // 2
						if grouped_length (integral.count + middle, spec.grouping) >= available then
							high := middle
						else
							low := middle + 1
						end
					end
					zero_count := low
					create Result.make (zero_count + integral.count)
					append_fill (Result, '0', zero_count)
					Result.append (integral)
					integral := Result
				end
			end
			if spec.grouping /= '%U' and not special then
				integral := grouped_digits (integral, spec.grouping)
			end
			Result := sign.twin
			if sign_padding and not special and spec.fill /= '0' then
				append_fill (Result, spec.fill, spec.width - sign.count - integral.count - tail.count)
			end
			Result.append (integral)
			Result.append (tail)
		ensure
			instance_free: class
		end

	grouped_length (count: INTEGER; separator: CHARACTER_32): INTEGER_64
			-- Length after grouping integral digits by threes, or their unchanged length.
			-- Use INTEGER_64 for size arithmetic so separator counts cannot overflow INTEGER_32.
		do
			Result := count
			if separator /= '%U' then
				Result := Result + (count - 1) // 3
			end
		ensure
			instance_free: class
		end

	grouped_digits (digits: STRING_32; separator: CHARACTER_32): STRING_32
			-- Return integral digits with a separator between groups of three counted from the right.
		local
			i: INTEGER
		do
			create Result.make (digits.count)
			from
				i := 1
			until
				i > digits.count
			loop
				if i > 1 and (digits.count - i + 1) \\ 3 = 0 then
					Result.append_character (separator)
				end
				Result.append_character (digits [i])
				i := i + 1
			end
		ensure
			instance_free: class
		end

	aligned_text (text: STRING_32; spec: like {SHABLON_FIELD_PARSER}.parsed_specification; numeric, special: BOOLEAN): STRING_32
			-- Return text filled to a minimum width without truncating or mutating its input.
			-- Width counts Unicode code points; an odd center fill goes on the right.
			-- Sign-aware alignment fills after the sign; nonfinite values ignore implicit zero fill.
		local
			padding, left: INTEGER
			alignment, fill: CHARACTER_32
		do
			alignment := spec.alignment
			fill := spec.fill
			if alignment = '%U' then
				if numeric then
					alignment := '>'
				else
					alignment := '<'
				end
			end
			if special and spec.zero and not spec.explicit_fill then
				fill := ' '
			end
			padding := (spec.width - text.count).max (0)
			if alignment = '^' then
				left := padding // 2
			elseif alignment = '>' or alignment = '=' then
				left := padding
			end
			create Result.make (text.count + padding)
			if alignment = '=' and then text.count > 0 and then (text [1] = '-' or text [1] = '+' or text [1] = ' ') then
				Result.append_character (text [1])
				append_fill (Result, fill, padding)
				Result.append (text.substring (2, text.count))
			else
				append_fill (Result, fill, left)
				Result.append (text)
				append_fill (Result, fill, padding - left)
			end
		ensure
			instance_free: class
		end

	append_fill (text: STRING_32; fill: CHARACTER_32; count: INTEGER)
			-- Append `count` copies of a character to an owned output buffer; nonpositive counts do nothing.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > count
			loop
				text.append_character (fill)
				i := i + 1
			end
		ensure
			instance_free: class
		end

end
