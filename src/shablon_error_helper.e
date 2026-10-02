note

	description:

		"Report a formatting failure with its category, template position and optional argument index."

	author: "samedit66"
	email: "samedit66@yandex.ru"
	date: "2026-10-03"

class SHABLON_ERROR_HELPER

feature {SHABLON, SHABLON_FIELD_PARSER, SHABLON_VALUE_FORMATTER} -- Errors

	fail (category: READABLE_STRING_8; position, index: INTEGER)
			-- Raise SHABLON_FORMAT_ERROR with its category, original position and optional argument index.
			-- Use an explicit exception so malformed input is rejected with assertions disabled too.
		local
			error: SHABLON_FORMAT_ERROR
		do
			create error.make (category, position, index)
			error.raise
		ensure
			instance_free: class
		end

end
