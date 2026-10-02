note

	description:

		"Demonstrate positional substitution, literal braces and numeric presentation with SHABLON."

	author: "samedit66"
	email: "samedit66@yandex.ru"
	date: "2026-10-03"

class DEMO_APPLICATION

inherit

	SHABLON

create

	make

feature {NONE} -- Initialization

	make
			-- Print examples of substitution, escapes and numeric presentation with both call styles.
		do
			io.put_string (format ("Hello, {}!", "Alice").to_string_8)
			io.put_new_line
			io.put_string ({SHABLON}.format ("{0} invited {1}; thank you, {0}!", "Alice", "Bob").to_string_8)
			io.put_new_line
			io.put_string (format ("Value: {{{}}}", 42).to_string_8)
			io.put_new_line
			io.put_string (format ("Total: {:,.2f}; change: {:+08.2f}; measurement: {:.2e}", 12345.5, 1.25, 12345.0).to_string_8)
			io.put_new_line
		end

end
