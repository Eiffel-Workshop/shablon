class DEMO_APPLICATION

inherit

	SHABLON

create

	make

feature {NONE} -- Initialization

	make
		do
			io.put_string (format ("Hello, {}!", ["Alice"]).to_string_8)
			io.put_new_line
			io.put_string ({SHABLON}.format ("{0} invited {1}; thank you, {0}!", ["Alice", "Bob"]).to_string_8)
			io.put_new_line
			io.put_string (format ("Value: {{{}}}", [42]).to_string_8)
			io.put_new_line
		end

end
