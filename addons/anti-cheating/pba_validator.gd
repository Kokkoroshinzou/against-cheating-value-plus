extends ac_validator

var _hash: String = ""
var _source: PackedByteArray = PackedByteArray()

func with(value: PackedByteArray) -> ac_validator:
	_source = value
	_hash = hash_value(value)
	return self

func check(value: PackedByteArray) -> bool:
	return hash_value(value) == _hash

func source():
	return _source

func hash_value(value: PackedByteArray) -> String:
	# Create a HashingContext instance
	var hashing_context = HashingContext.new()
	
	# Start the MD5 hashing process
	if hashing_context.start(HashingContext.HASH_MD5) == OK:
		# Pass the data to the hashing context
		hashing_context.update(value)
		# Finish the hashing process and get the hash as a PackedByteArray
		var hash = hashing_context.finish()
		# Convert the hash to a readable hex string
		return hash.hex_encode()
	else:
		push_error("Failed to initialize HashingContext with MD5")
		return ""
	
	
	
	
	
	
	
	
	
