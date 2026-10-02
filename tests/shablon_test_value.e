note

	description:

		"Provide observable text conversion and a controlled exception for formatting tests."

	author: "samedit66"
	email: "samedit66@yandex.ru"
	date: "2026-10-03"

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
			-- Create a stable exception instance for verifying original failure propagation.
		do
			create failure
			failure.set_description ("Test out failure")
		end

feature -- Access

	calls: INTEGER
			-- Number of intentionally observable out calls.

	failure: DEVELOPER_EXCEPTION
			-- Stable exception used to test identity-preserving propagation.

	raises_error: BOOLEAN
			-- Should the next out call raise the stable test exception?

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
			-- Configure whether subsequent out calls raise the stable test exception.
		do
			raises_error := a_value
		end

end
