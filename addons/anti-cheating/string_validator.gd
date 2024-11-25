extends ac_validator

var _hash: String = ""
var _source: String = ""

func with(value: String) -> ac_validator:
	_source = value
	_hash = hash_value(value)
	return self

func check(value: String) -> bool:
	return hash_value(value) == _hash

func source():
	return _source

func hash_value(value: String) -> String:
	# A simple hash function that returns a hex string
	return value.md5_text()
