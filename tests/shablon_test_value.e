class SHABLON_TEST_VALUE

inherit

	ANY
		redefine
			out
		end

create

	make

feature {NONE} -- Initialization

	make
		do
			create failure
			failure.set_description ("Test out failure")
		end

feature -- Access

	calls: INTEGER

	failure: DEVELOPER_EXCEPTION

	raises_error: BOOLEAN

	out: STRING
			-- Deliberately observable rendering for testing call order and propagation.
		do
			calls := calls + 1
			if raises_error then
				failure.raise
			end
			Result := calls.out
		end

feature -- Settings

	set_raises_error (a_value: BOOLEAN)
		do
			raises_error := a_value
		end

end
