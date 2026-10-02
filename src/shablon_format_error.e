class SHABLON_FORMAT_ERROR

inherit

	DEVELOPER_EXCEPTION

create

	make

feature {NONE} -- Initialization

	make (a_category: READABLE_STRING_8; a_position, a_field_index: INTEGER)
			-- Error with a one-based position and an optional zero-based field index.
		require
			positive_position: a_position > 0
			valid_field_index: a_field_index >= -1
		local
			text: STRING_8
		do
			create category.make_from_string (a_category)
			position := a_position
			field_index := a_field_index
			text := category.to_string_8 + " at position " + position.out
			if has_field_index then
				text.append (" (field " + field_index.out + ")")
			end
			set_description (text)
		end

feature -- Access

	category: IMMUTABLE_STRING_8
			-- Stable error category.

	position: INTEGER
			-- One-based character position in the template.

	field_index: INTEGER
			-- Zero-based argument index, or -1 when unavailable.

	has_field_index: BOOLEAN
			-- Is an argument index available?
		do
			Result := field_index >= 0
		end

feature -- Categories

	invalid_field: IMMUTABLE_STRING_8
		once
			create Result.make_from_string ("invalid_field")
		ensure
			instance_free: class
		end

	unexpected_closing_brace: IMMUTABLE_STRING_8
		once
			create Result.make_from_string ("unexpected_closing_brace")
		ensure
			instance_free: class
		end

	mixed_field_modes: IMMUTABLE_STRING_8
		once
			create Result.make_from_string ("mixed_field_modes")
		ensure
			instance_free: class
		end

	index_out_of_range: IMMUTABLE_STRING_8
		once
			create Result.make_from_string ("index_out_of_range")
		ensure
			instance_free: class
		end

	missing_argument: IMMUTABLE_STRING_8
		once
			create Result.make_from_string ("missing_argument")
		ensure
			instance_free: class
		end

	void_argument: IMMUTABLE_STRING_8
		once
			create Result.make_from_string ("void_argument")
		ensure
			instance_free: class
		end

end
