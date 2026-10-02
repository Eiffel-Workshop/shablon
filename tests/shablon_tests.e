class SHABLON_TESTS

inherit

	TS_TEST_CASE

	SHABLON

create

	make_default

feature -- Tests

	test_automatic_fields
		do
			assert_text ("Hello, Alice!", format ("Hello, {}!", ["Alice"]))
			assert_text ("Alice has 42 messages.", {SHABLON}.format ("{} has {} messages.", ["Alice", 42]))
			assert_text ("ab", format ("{}{}", ["a", "b"]))
		end

	test_numbered_fields
		do
			assert_text ("b/a/b", format ("{1}/{0}/{1}", ["a", "b"]))
			assert_text ("Alice invited Bob; thank you, Alice!", format ("{0} invited {1}; thank you, {0}!", ["Alice", "Bob"]))
			assert_text ("10", format ("{10}", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))
		end

	test_braces
		do
			assert_text ("{}", format ("{{}}", []))
			assert_text ("{42}", format ("{{{0}}}", [42]))
			assert_text ("Value: {42}", format ("Value: {{{}}}", [42]))
			assert_text ("{{}}", format ("{{{{}}}}", []))
			assert_text ("Received: {name}", format ("Received: {}", ["{name}"]))
		end

	test_empty_and_unused_values
		local
			nothing: detachable ANY
		do
			assert_text ("", format ("", []))
			assert_text ("", format ("{}", [""]))
			assert_text ("Hello", format ("Hello", [nothing, 42]))
			assert_text ("used", format ("{1}", [nothing, "used"]))
			assert_text ("used", format ("{}", ["used", nothing]))
		end

	test_unicode_text
		local
			text: STRING_32
		do
			text := {STRING_32} "Привет, 世界! %/128578/"
			assert_text (text, format ("{}", [text]))
			assert_text ({STRING_32} "Привет, 世界!", format ({STRING_32} "Привет, {}!", [{STRING_32} "世界"]))
			assert_text ("é", format ("{}", ["é"]))
		end

	test_values_use_out
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
		local
			value: TUPLE
		do
			value := ["a", 42]
			assert_text (value.out, format ("{}", [value]))
		end

	test_result_ownership
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
			assert_true ("tuple item is preserved", arguments [1] = value)
			second := format (template, arguments)
			assert_text ("Hello, Alice!", second)
			assert_true ("results are independent", second /= result_text)
			result_text := format (value, [])
			result_text.append_character ('!')
			assert_text ("Alice", value)
		end

	test_custom_out_order_and_failures
		local
			value: SHABLON_TEST_VALUE
		do
			create value.make
			assert_text ("1/2/3", format ("{0}/{0}/{0}", [value]))
			assert_integers_equal ("one out call per occurrence", 3, value.calls)
			value.set_raises_error (True)
			assert_true ("out failure propagates unchanged", exception_from ("{}", [value]) = value.failure)
			assert_text ("ok", format ("ok", [value]))
			assert_text ("next", format ("{}", ["next"]))
		end

	test_invalid_fields
		do
			assert_error ("{", [], "invalid_field", 1, -1)
			assert_error ("{01}", ["a", "b"], "invalid_field", 1, -1)
			assert_error ("{name}", ["Alice"], "invalid_field", 1, -1)
			assert_error ("{:d}", [42], "invalid_field", 1, -1)
			assert_error ("{ 0}", [42], "invalid_field", 1, -1)
			assert_error ("{-1}", [42], "invalid_field", 1, -1)
			assert_error ("{{{x}}}", [], "invalid_field", 3, -1)
			assert_error ("{٠}", [42], "invalid_field", 1, -1)
			assert_error ("a}", [], "unexpected_closing_brace", 2, -1)
		end

	test_mixed_modes
		do
			assert_error ("{} {0}", ["a"], "mixed_field_modes", 4, -1)
			assert_error ("{0} {}", ["a"], "mixed_field_modes", 5, -1)
			assert_error ("{} {2147483648}", ["a"], "mixed_field_modes", 4, -1)
			assert_error ("{} {999999999999x}", ["a"], "invalid_field", 4, -1)
			assert_text ("{a}", format ("{{{}}}", ["a"]))
		end

	test_argument_errors
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
		do
			assert_error ("{2147483647}", [], "missing_argument", 1, 2147483647)
			assert_error ("{2147483648}", [], "index_out_of_range", 1, -1)
			assert_error ("{999999999999999999999999999999999}", [], "index_out_of_range", 1, -1)
			assert_error ("{999999999999999999999x}", [], "invalid_field", 1, -1)
		end

	test_first_error_and_character_position
		do
			assert_error ("{} {bad}", [], "missing_argument", 1, 0)
			assert_error ("{bad} {}", [], "invalid_field", 1, -1)
			assert_error ({STRING_32} "%/128578/}", [], "unexpected_closing_brace", 2, -1)
			assert_text ("ok", format ("{}", ["ok"]))
		end

	test_assertion_configuration
		local
			environment: EXECUTION_ENVIRONMENT
		do
			create environment
			if attached environment.item ("SHABLON_ASSERTIONS") as setting then
				assert_booleans_equal ("configured assertion mode", setting.same_string_general ("on"), preconditions_enabled)
			else
				assert_true ("assertion mode supplied by test recipe", False)
			end
		end

feature {NONE} -- Helpers

	assert_text (a_expected: READABLE_STRING_GENERAL; a_actual: STRING_32)
		do
			assert_true ("text matches", a_actual.same_string_general (a_expected))
		end

	value_out (a_value: separate ANY): STRING
		do
			create Result.make_from_separate (a_value.out)
		end

	assert_error (a_template: READABLE_STRING_GENERAL; a_arguments: TUPLE; a_category: STRING; a_position, a_index: INTEGER)
		do
			if attached {SHABLON_FORMAT_ERROR} exception_from (a_template, a_arguments) as error then
				assert_strings_equal ("error category", a_category, error.category.to_string_8)
				assert_integers_equal ("error position", a_position, error.position)
				assert_integers_equal ("field index", a_index, error.field_index)
				assert_booleans_equal ("field index availability", a_index >= 0, error.has_field_index)
				assert_true ("readable diagnostic", attached error.description as text and then text.has_substring (a_category))
			else
				assert_true ("expected SHABLON_FORMAT_ERROR", False)
			end
		end

	exception_from (a_template: READABLE_STRING_GENERAL; a_arguments: TUPLE): detachable EXCEPTION
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
		require
			allowed: a_allowed
		do
		end

end
