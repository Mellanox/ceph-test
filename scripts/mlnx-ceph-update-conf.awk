#! /usr/bin/awk -f

function print_key_val(key, val)
{
	if (length(val) != 0)
		print key, val
	is_printed = true
}

BEGIN {
	FS = OFS = "="
	current_section = ""
	is_printed = false
	is_section_found = false
}

# Skip comments
/^[:space]*#/ {print $0; next}
/^[:space]*;/ {print $0; next}

# Get current section
/^[:space]*\[.*\]/ {
        if (current_section ~ /\[[:space]*section[:space]*\]/) {
		# Leaving our section, add the key
		print_key_val(key, value)
	}

	current_section = $1

	if (current_section ~ section)
		is_section_found = true
}

# Skip other sections
current_section !~ section {print $0; next}

# Skip other keys
$1 != key {print $0; next}

# Update our key
$1 == key {
	print_key_val(key, value)
}

END {
	if (length(value) != 0 && !is_printed) {
		if (!is_section_found) {
			print "["section"]"
		}

		print_key_val(key, value)
	}
}
