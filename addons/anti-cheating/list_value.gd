extends ac_value
class_name ac_list

var _value: PackedByteArray = PackedByteArray()  # Serialized data stored as PackedByteArray
var _validator: ac_validator

# Initialize with any array or dictionary
func _init(data, parent: ac_list = null, parent_key: Variant = null):
	if data is not Array and data is not Dictionary:
		push_error("Data must be an Array or Dictionary.")
		return
	_value = _serialize_data(data)
	_validator = _get_validator().with(_value)
	_parent = parent
	_parent_key = parent_key

# Serialize the data into a PackedByteArray
func _serialize_data(data) -> PackedByteArray:
	if data is not Array and data is not Dictionary:
		push_error("Data must be an Array or Dictionary.")
		return PackedByteArray()
	return var_to_bytes(data)

# Deserialize the PackedByteArray into Variant
func _deserialize_data() -> Variant:
	if not _validator.check(_value):
		push_error("Validation failed.")
		return bytes_to_var(_validator.source())
	return bytes_to_var(_value)

func set_value(key, value):
	var data = _deserialize_data()  # Cache the deserialized data
	if data is Dictionary:
		if value is ac_value:
			value = value.value()
		elif value is PackedByteArray:
			value = bytes_to_var(value)
		data[key] = value
		_value = _serialize_data(data)
		_validator.with(_value)
		_notify_parent()
	elif data is Array:
		var index = key.to_int()
		if index >= 0 and index < data.size():
			if value is ac_value:
				value = value.value()
			elif value is PackedByteArray:
				value = bytes_to_var(value)
			data[index] = value
			_value = _serialize_data(data)
			_validator.with(_value)
			_notify_parent()
		else:
			push_error("Index out of bounds or invalid key.")
	else:
		push_error("Unsupported data structure.")

func get_value(key: String, default_value: ac_value = ac_value.new()) -> Variant:
	var data = _deserialize_data()  # Cache the deserialized data
	if data is Dictionary:
		if !data.has(key):
			push_error("Key not found in dictionary: %s" % key)
			return default_value

		var value = data[key]
		return _wrap_value(value, key)

	elif data is Array:
		var index = key.to_int()
		if index < 0 or index >= data.size():
			push_error("Index out of bounds for array.")
			return default_value

		var value = data[index]
		return _wrap_value(value, key)

	push_error("Unsupported structure. Expected Array or Dictionary.")
	return default_value

func _wrap_value(value: Variant, key: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return ac_list.new(value, self, key)
	elif value is String:
		if value.is_valid_int():
			value = value.to_int()
			return ac_int.new(value, self, key)
		elif is_json(value):
			return ac_list.new(JSON.parse_string(value), self, key)
		return ac_string.new(value, self, key)
	elif value is int:
		return ac_int.new(value, self, key)
	elif value is float:
		return ac_float.new(value, self, key)
	elif value is bool:
		return ac_bool.new(value, self, key)
	elif value is NodePath:
		return value
	else:
		push_error("Unsupported data type for key '%s': %s" % [key, typeof(value)])
		return ac_value.new()

func _get_validator() -> ac_validator:
	return preload("pba_validator.gd").new()

func append(value):
	var data = _deserialize_data()
	if data is Array:
		data.append(value)
		_value = _serialize_data(data)
		_validator.with(_value)
		_notify_parent()
	else:
		push_error("Cannot append to a non-array structure.")

func parse() -> Variant:
	return _deserialize_data()

func remove_at(index: int):
	var data = _deserialize_data()
	if data is Array:
		if index >= 0 and index < data.size():
			data.remove_at(index)
			_value = _serialize_data(data)
			_validator.with(_value)
			_notify_parent()
		else:
			push_error("Index out of bounds.")
	else:
		push_error("Cannot use remove_at with Dictionary.")

func erase(value):
	var data = _deserialize_data()
	if data is Array:
		data.erase(value)
		_value = _serialize_data(data)
		_validator.with(_value)
		_notify_parent()
	elif data is Dictionary:
		data.erase(value)
		_value = _serialize_data(data)
		_validator.with(_value)
		_notify_parent()
	else:
		push_error("Unsupported data structure.")

func duplicate() -> ac_list:
	return ac_list.new(_deserialize_data(), null, null)

# Notify the parent of the update
func _notify_parent():
	if _parent:
		_parent.set_value(_parent_key, _value)

func merge(value):
	var data = _deserialize_data()
	if data is Dictionary:
		data.merge(value)
		_value = _serialize_data(data)
		_validator.with(_value)
		_notify_parent()
	else:
		push_error("Cannot use merge with Array.")

# Override _get to allow subscript access
func _get(key: Variant) -> Variant:
	return get_value(key)

func has(value):
	var data = _deserialize_data()
	if data is Dictionary:
		return data.has(value)
	elif data is Array:
		return data.has(value)
	else:
		push_error("Unsupported data structure.")
		return false

func keys():
	var data = _deserialize_data()
	if data is Dictionary:
		return data.keys()
	else:
		push_error("Cannot use keys with Array.")
		return []

func sort_custom(value: Callable):
	var data = _deserialize_data()
	if data is Array:
		data.sort_custom(value)
		_value = _serialize_data(data)
		_validator.with(_value)
		_notify_parent()
	else:
		push_error("Cannot use sort_custom with Dictionary.")

func any(value: Callable):
	var data = _deserialize_data()
	if data is Array:
		return data.any(value)
	else:
		push_error("Cannot use any with Dictionary.")
		return false

func is_empty():
	var data = _deserialize_data()
	return data.is_empty()

# Override _set to allow subscript assignment
func _set(key: Variant, value: Variant):
	set_value(key, value)

func size() -> int:
	var data = _deserialize_data()
	return data.size()

func is_json(value):
	var json = JSON.new()
	var result = json.parse(value)
	return result == OK
