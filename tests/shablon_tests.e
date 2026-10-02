note

	description:

		"Verify template syntax, value presentation, Unicode handling and formatting failure diagnostics."

	author: "samedit66"
	email: "samedit66@yandex.ru"
	date: "2026-10-03"

class SHABLON_TESTS

inherit

	TS_TEST_CASE

	SHABLON

create

	make_default

feature -- Tests

	test_automatic_fields
			-- Verify positional substitution and both inherited and class-call interfaces.
		do
			assert_text ("Hello, Alice!", format ("Hello, {}!", "Alice"))
			assert_text ("Alice has 42 messages.", {SHABLON}.format ("{} has {} messages.", "Alice", 42))
			assert_text ("ab", format ("{}{}", "a", "b"))
		end

	test_numbered_fields
			-- Verify reordered, repeated and multi-digit argument indices.
		do
			assert_text ("b/a/b", format ("{1}/{0}/{1}", "a", "b"))
			assert_text ("Alice invited Bob; thank you, Alice!", format ("{0} invited {1}; thank you, {0}!", "Alice", "Bob"))
			assert_text ("10", format ("{10}", 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10))
		end

	test_braces
			-- Verify literal brace escapes and that inserted values are never parsed.
		do
			assert_text ("{}", format ("{{}}", []))
			assert_text ("{42}", format ("{{{0}}}", 42))
			assert_text ("Value: {42}", format ("Value: {{{}}}", 42))
			assert_text ("{{}}", format ("{{{{}}}}", []))
			assert_text ("Received: {name}", format ("Received: {}", "{name}"))
		end

	test_empty_and_unused_values
			-- Verify empty inputs and ignored unused arguments, including void items.
		local
			nothing: detachable ANY
		do
			assert_text ("", format ("", []))
			assert_text ("", format ("{}", ""))
			assert_text ("Hello", format ("Hello", nothing, 42))
			assert_text ("used", format ("{1}", nothing, "used"))
			assert_text ("used", format ("{}", "used", nothing))
		end

	test_unicode_text
			-- Verify Unicode code points in templates and values. Numeric escapes avoid Gobo literal byte widening.
		local
			text: STRING_32
		do
			text := {STRING_32} "%/1055/%/1088/%/1080/%/1074/%/1077/%/1090/, %/19990/%/30028/! %/128578/"
			assert_text (text, format ("{}", text))
			assert_text ({STRING_32} "%/1055/%/1088/%/1080/%/1074/%/1077/%/1090/, %/19990/%/30028/!", format ({STRING_32} "%/1055/%/1088/%/1080/%/1074/%/1077/%/1090/, {}!", {STRING_32} "%/19990/%/30028/"))
			assert_text ("%/233/", format ("{}", "%/233/"))
		end

	test_values_use_out
			-- Verify native representations of all integer and real sizes, booleans and characters.
		local
			values: TUPLE
			expected: STRING_32
			i: INTEGER
		do
			values := [{INTEGER_8} -8, {INTEGER_16} -16, {INTEGER_32} -32, {INTEGER_64} -64, {NATURAL_8} 8, {NATURAL_16} 16, {NATURAL_32} 32, {NATURAL_64} 64, {REAL_32} 1.5, {REAL_64} 2.5, True, 'x', {CHARACTER_32} '%/1046/']
			create expected.make_empty
			from
				i := 1
			until
				i > values.count
			loop
				if attached values [i] as value then
					expected.append_string_general (value_out (value))
				end
				i := i + 1
			end
			assert_text (expected, format ("{}{}{}{}{}{}{}{}{}{}{}{}{}", values))
		end

	test_tuple_value_is_not_expanded
			-- Verify a tuple passed as one argument is rendered without recursive expansion.
		local
			value: TUPLE
		do
			value := ["a", 42]
			assert_text (value.out, format ("{}", [value]))
		end

	test_result_ownership
			-- Verify inputs are preserved and results remain independently mutable.
		local
			template, value, result_text, second: STRING_32
			arguments: TUPLE
		do
			template := {STRING_32} "Hello, {}!"
			value := {STRING_32} "Alice"
			arguments := [value]
			result_text := format (template, arguments)
			result_text.wipe_out
			assert_text ("Hello, {}!", template)
			assert_text ("Alice", value)
			assert_same ("tuple item is preserved", value, arguments [1])
			second := format (template, arguments)
			assert_text ("Hello, Alice!", second)
			assert_not_same ("results are independent", result_text, second)
			result_text := format (value, [])
			result_text.append_character ('!')
			assert_text ("Alice", value)
		end

	test_custom_out_order_and_failures
			-- Verify one out call per occurrence, original exception propagation and subsequent calls.
		local
			value: SHABLON_TEST_VALUE
		do
			create value.make
			assert_text ("1/2/3", format ("{0}/{0}/{0}", value))
			assert_integers_equal ("one out call per occurrence", 3, value.calls)
			value.set_raises_error (True)
			assert_same ("out failure propagates unchanged", value.failure, exception_from ("{}", [value]))
			assert_text ("ok", format ("ok", value))
			assert_text ("next", format ("{}", "next"))
		end

	test_invalid_fields
			-- Verify malformed fields report the original template position.
		do
			assert_error ("{", [], "invalid_field", 1, -1)
			assert_error ("{01}", ["a", "b"], "invalid_field", 1, -1)
			assert_error ("{name}", ["Alice"], "invalid_field", 1, -1)
			assert_text ("42", format ("{:d}", 42))
			assert_error ("{ 0}", [42], "invalid_field", 1, -1)
			assert_error ("{-1}", [42], "invalid_field", 1, -1)
			assert_error ("{{{x}}}", [], "invalid_field", 3, -1)
			assert_error ({STRING_32} "{%/1632/}", [42], "invalid_field", 1, -1)
			assert_error ("a}", [], "unexpected_closing_brace", 2, -1)
		end

	test_mixed_modes
			-- Verify automatic and numbered modes cannot mix and syntax precedes index-range checking.
		do
			assert_error ("{} {0}", ["a"], "mixed_field_modes", 4, -1)
			assert_error ("{0} {}", ["a"], "mixed_field_modes", 5, -1)
			assert_error ("{} {2147483648}", ["a"], "mixed_field_modes", 4, -1)
			assert_error ("{} {999999999999x}", ["a"], "invalid_field", 4, -1)
			assert_text ("{a}", format ("{{{}}}", "a"))
		end

	test_argument_errors
			-- Verify missing and selected void arguments report their zero-based indices.
		local
			nothing: detachable ANY
		do
			assert_error ("{0}", [], "missing_argument", 1, 0)
			assert_error ("{} {}", ["a"], "missing_argument", 4, 1)
			assert_error ("{1}", [42], "missing_argument", 1, 1)
			assert_error ("{}", [nothing], "void_argument", 1, 0)
			assert_error ("{1}", [42, nothing], "void_argument", 1, 1)
		end

	test_index_overflow
			-- Verify index overflow detection and safe lookup at the maximum representable index.
		do
			assert_error ("{2147483647}", [], "missing_argument", 1, 2147483647)
			assert_error ("{2147483648}", [], "index_out_of_range", 1, -1)
			assert_error ("{999999999999999999999999999999999}", [], "index_out_of_range", 1, -1)
			assert_error ("{999999999999999999999x}", [], "invalid_field", 1, -1)
		end

	test_first_error_and_character_position
			-- Verify left-to-right failure precedence and positions measured in Unicode code points.
		do
			assert_error ("{} {bad}", [], "missing_argument", 1, 0)
			assert_error ("{bad} {}", [], "invalid_field", 1, -1)
			assert_error ({STRING_32} "%/128578/}", [], "unexpected_closing_brace", 2, -1)
			assert_text ("ok", format ("{}", "ok"))
		end

	test_assertion_configuration
			-- Verify the requested assertion mode using a deliberately failing precondition.
		local
			environment: EXECUTION_ENVIRONMENT
		do
			create environment
			if attached environment.item ("SHABLON_ASSERTIONS") as setting then
				assert_booleans_equal ("configured assertion mode", setting.same_string_general ("on"), preconditions_enabled)
			else
				assert_not_equal ("assertion mode supplied by test recipe", Void, environment.item ("SHABLON_ASSERTIONS"))
			end
		end

	test_fixed_precision_and_rounding
			-- Verify exact binary-value rounding, ties to even, carry and fractional zero padding.
		do
			assert_text ("12.50", format ("{:.2f}", 12.5))
			assert_text ("12", format ("{:.0f}", 12.0))
			assert_text ("2", format ("{:.0f}", 2.5))
			assert_text ("4", format ("{:.0f}", 3.5))
			assert_text ("-2", format ("{:.0f}", -2.5))
			assert_text ("2.67", format ("{:.2f}", 2.675))
			assert_text ("1.12", format ("{:.2f}", 1.125))
			assert_text ("1.38", format ("{:.2f}", 1.375))
			assert_text ("10.00", format ("{:.2f}", 9.999))
			assert_text ("0.00", format ("{:.2f}", 0.001))
			assert_text ("0.50000000000000000000", format ("{:.20f}", 0.5))
			assert_text ("1.250000", format ("{:f}", 1.25))
			assert_text ("12.00", format ("{:.2f}", 12))
			assert_text ("0.10000000149011611938", format ("{:.20f}", {REAL_32} 0.1))
		end

	test_scientific_notation
			-- Verify exponents, rounding carry, exact integer input and the extremes of REAL_64.
		local
			smallest: REAL_64
		do
				-- Construct at run time: ISE melted code underflows subnormal literals.
			smallest := {REAL_64}.epsilon
			smallest := smallest / 4503599627370496.0
			assert_text ("1.23e+04", format ("{:.2e}", 12345.0))
			assert_text ("1.00e+01", format ("{:.2e}", 9.999))
			assert_text ("1e+01", format ("{:.0e}", 9.999))
			assert_text ("1.25E-03", format ("{:.2E}", 0.00125))
			assert_text ("0.00e+00", format ("{:.2e}", 0.0))
			assert_text ("1.250000e+00", format ("{:e}", 1.25))
			assert_text ("1.84e+19", format ("{:.2e}", {NATURAL_64} 18446744073709551615))
			assert_text ("-1.00e+20", format ("{:.2e}", -1.0e20))
			assert_text ("4.94e-324", format ("{:.2e}", smallest))
			assert_text ("1.80e+308", format ("{:.2e}", 1.7976931348623157e308))
			assert_text ("-100000000000000000000.00", format ("{:.2f}", -1.0e20))
		end

	test_integer_ranges
			-- Verify formatting preserves the full magnitude of every signed and unsigned integer size.
		do
			assert_text ("-2,147,483,648", format ("{:,d}", {INTEGER_32}.min_value))
			assert_text ("-9,223,372,036,854,775,808", format ("{:,d}", {INTEGER_64}.min_value))
			assert_text ("18,446,744,073,709,551,615", format ("{:,d}", {NATURAL_64}.max_value))
			assert_text ("18446744073709551615.00", format ("{:.2f}", {NATURAL_64}.max_value))
			assert_text ("-9223372036854775808.00", format ("{:.2f}", {INTEGER_64}.min_value))
			assert_text ("9007199254740993.00", format ("{:.2f}", {INTEGER_64} 9007199254740993))
			assert_text ("-8/-16/-32/-64/8/16/32/64", format ("{:d}/{:d}/{:d}/{:d}/{:d}/{:d}/{:d}/{:d}", {INTEGER_8} -8, {INTEGER_16} -16, {INTEGER_32} -32, {INTEGER_64} -64, {NATURAL_8} 8, {NATURAL_16} 16, {NATURAL_32} 32, {NATURAL_64} 64))
		end

	test_grouping_and_signs
			-- Verify decimal grouping and negative-only, explicit-positive and space sign policies.
		do
			assert_text ("1,234,567", format ("{:,d}", 1234567))
			assert_text ("1_234_567", format ("{:_d}", 1234567))
			assert_text ("12,345.50", format ("{:,.2f}", 12345.5))
			assert_text ("+42 -42 +0", format ("{:+d} {:+d} {:+d}", 42, -42, 0))
			assert_text (" 42 -42  0", format ("{: d} {: d} {: d}", 42, -42, 0))
			assert_text ("+1.23e+04", format ("{:+.2e}", 12345.0))
			assert_text ("1.23e+04", format ("{:,.2e}", 12345.0))
			assert_text ("42", format ("{:-d}", 42))
			assert_text ("1,234", format ("{:,}", 1234))
		end

	test_width_alignment_and_zero_fill
			-- Verify minimum widths, alignment, custom fill and grouped sign-aware zero padding.
		do
			assert_text ("    42", format ("{:>6d}", 42))
			assert_text ("42    ", format ("{:<6d}", 42))
			assert_text (" 42  ", format ("{:^5d}", 42))
			assert_text ("****42", format ("{:*>6d}", 42))
			assert_text ("-00042", format ("{:06d}", -42))
			assert_text ("+00042", format ("{:+06d}", 42))
			assert_text ("000-42", format ("{:0>6d}", -42))
			assert_text ("42", format ("{:1d}", 42))
			assert_text ("-0001.25", format ("{:08.2f}", -1.25))
			assert_text ("00,001,234", format ("{:010,d}", 1234))
			assert_text ("0,001,234", format ("{:08,d}", 1234))
			assert_text ("42****", format ("{:*<06d}", 42))
			assert_text ("   -42", format ("{: >06d}", -42))
			assert_text ("-   42", format ("{:=6d}", -42))
			assert_text ("+0,001,234.50", format ("{:+012,.2f}", 1234.5))
		end

	test_text_alignment_and_specified_fields
			-- Verify Unicode fill, repeated presentations and one custom out call per occurrence.
		local
			value: SHABLON_TEST_VALUE
		do
			assert_text ("Alice   ", format ("{:8}", "Alice"))
			assert_text ("   Alice", format ("{:>8}", "Alice"))
			assert_text ({STRING_32} "%/19990/%/30028/%/183/%/183/%/183/", format ({STRING_32} "{:%/183/<5}", {STRING_32} "%/19990/%/30028/"))
			assert_text ("{ 12.50}", format ("{{{:6.2f}}}", 12.5))
			assert_text ("12.50/1.2e+01", format ("{0:.2f}/{0:.1e}", 12.5))
			assert_text ("{:.2f}", format ("{:>2}", "{:.2f}"))
			assert_text ("42", format ("{:}", 42))
			create value.make
			assert_text ("  1/  2", format ("{0:>3}/{0:>3}", value))
			assert_integers_equal ("out remains once per occurrence", 2, value.calls)
		end

	test_special_floating_point_values
			-- Verify signed zero, nonfinite spelling and implicit versus explicit padding.
		do
			assert_text ("-0.00", format ("{:.2f}", -0.0))
			assert_text ("-0.00e+00", format ("{:.2e}", -0.0))
			assert_text ("+0.00", format ("{:+.2f}", 0.0))
			assert_text ("-0.00", format ("{:.2f}", -0.001))
			assert_text ("inf", format ("{:.2f}", {REAL_64}.positive_infinity))
			assert_text ("-inf", format ("{:.2e}", {REAL_64}.negative_infinity))
			assert_text ("NAN", format ("{:.2E}", {REAL_64}.nan))
			assert_text ("    +inf", format ("{:+08.2f}", {REAL_64}.positive_infinity))
			assert_text (({REAL_64}.nan).out, format ("{}", {REAL_64}.nan))
			assert_text ("*****inf", format ("{:*>08.2f}", {REAL_64}.positive_infinity))
			assert_text ("00000inf", format ("{:0>08.2f}", {REAL_64}.positive_infinity))
			assert_text ("-    inf", format ("{:=8f}", {REAL_64}.negative_infinity))
		end

	test_specification_errors
			-- Verify syntax, size and value-type errors precede inappropriate rendering.
		local
			value: SHABLON_TEST_VALUE
		do
			assert_error ("{:.}", [1.0], "invalid_specification", 1, -1)
			assert_error ("{:.2}", [1.0], "invalid_specification", 1, -1)
			assert_error ("{:.2d}", [42], "invalid_specification", 1, -1)
			assert_error ("{:q}", [42], "invalid_specification", 1, -1)
			assert_error ("{:6+d}", [42], "invalid_specification", 1, -1)
			assert_error ("{:2147483648d}", [42], "invalid_specification", 1, -1)
			assert_error ("{:.2147483648f}", [1.0], "invalid_specification", 1, -1)
			assert_error ("a{:.2f}", ["12.5"], "incompatible_format", 2, 0)
			assert_error ("{:d}", [1.5], "incompatible_format", 1, 0)
			assert_error ("{:+}", ["text"], "incompatible_format", 1, 0)
			assert_error ("{:-}", ["text"], "incompatible_format", 1, 0)
			assert_error ("{:=6}", ["text"], "incompatible_format", 1, 0)
			assert_error ("{:06}", ["text"], "incompatible_format", 1, 0)
			assert_error ("{:,}", [True], "incompatible_format", 1, 0)
			assert_error ("{} {0:.2f}", [42], "mixed_field_modes", 4, -1)
			assert_error ("{:.2f}", [], "missing_argument", 1, 0)
			assert_error ("{:q}", [], "invalid_specification", 1, -1)
			assert_error ("{:.2147483647f}", [1.0], "invalid_specification", 1, -1)
			assert_error ("{:.2147483647f}", [], "invalid_specification", 1, -1)
			create value.make
			assert_error ("{:.2f}", [value], "incompatible_format", 1, 0)
			assert_integers_equal ("incompatible presentation does not call out", 0, value.calls)
		end

feature {NONE} -- Helpers

	assert_text (a_expected: READABLE_STRING_GENERAL; a_actual: STRING_32)
			-- Compare text with expected/actual diagnostics, encoding Unicode as UTF-8 for getest.
			-- assert_strings_equal takes STRING_8; UTF-8 preserves code points without narrowing.
		do
			assert_strings_equal ("text matches", {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_expected), {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_actual))
		end

	value_out (a_value: separate ANY): STRING
			-- Copy native out text under a controlled separate argument for both compiler profiles.
		do
			create Result.make_from_separate (a_value.out)
		end

	assert_error (a_template: READABLE_STRING_GENERAL; a_arguments: TUPLE; a_category: STRING; a_position, a_index: INTEGER)
			-- Verify exception type, metadata and the entire diagnostic with expected/actual values.
		local
			caught: detachable EXCEPTION
			expected_description, actual_description, actual_type: STRING
		do
			caught := exception_from (a_template, a_arguments)
			if attached {SHABLON_FORMAT_ERROR} caught as error then
				assert_strings_equal ("error category", a_category, error.category.to_string_8)
				assert_integers_equal ("error position", a_position, error.position)
				assert_integers_equal ("field index", a_index, error.field_index)
				assert_booleans_equal ("field index availability", a_index >= 0, error.has_field_index)
				expected_description := a_category + " at position " + a_position.out
				if a_index >= 0 then
					expected_description.append (" (field " + a_index.out + ")")
				end
				actual_description := "Void"
				if attached error.description as text then
					actual_description := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (text)
				end
				assert_strings_equal ("readable diagnostic", expected_description, actual_description)
			else
				actual_type := "Void (no exception)"
				if attached caught as error then
					actual_type := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (error.generating_type.name_32)
				end
				assert_strings_equal ("exception type", "SHABLON_FORMAT_ERROR", actual_type)
			end
		end

	exception_from (a_template: READABLE_STRING_GENERAL; a_arguments: TUPLE): detachable EXCEPTION
			-- Capture the original exception from formatting, or return Void on success.
		local
			retried: BOOLEAN
			text: STRING_32
		do
			if not retried then
				text := format (a_template, a_arguments)
			end
		rescue
			if attached {EXCEPTION_MANAGER_FACTORY}.exception_manager.last_exception as error then
				Result := error.original
			end
			retried := True
			retry
		end

	preconditions_enabled: BOOLEAN
			-- Probe runtime precondition checking; Gobo's ECF check flag currently sets the invariant flag.
		local
			retried: BOOLEAN
		do
			if not retried then
				assertion_probe (False)
			else
				Result := True
			end
		rescue
			retried := True
			retry
		end

	assertion_probe (a_allowed: BOOLEAN)
			-- Do nothing when permitted; its precondition deliberately fails for the assertion-mode probe.
		require
			allowed: a_allowed
		do
		end

end
