extends ac_validator

var _hash: String = ""
var _source: bool = false
var _salt: String = ""  # Unique salt for this validator

func with(value: bool) -> ac_validator:
	_source = value
	_salt = generate_salt()
	_hash = hash_value(value)
	return self

func check(value: bool) -> bool:
	return hash_value(value) == _hash

func source():
	return _source

func hash_value(value: bool) -> String:
	# Combine the salt and value for hashing
	return (_salt + str(value)).md5_text()

func generate_salt() -> String:
	# Generate a random string as the salt
	var rand_bytes = PackedByteArray()
	for i in range(8):  # 8-byte salt for uniqueness
		rand_bytes.append(randf_range(0, 255))
	return rand_bytes.hex_encode()
