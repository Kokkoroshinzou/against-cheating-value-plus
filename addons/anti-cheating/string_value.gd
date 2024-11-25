extends ac_value
class_name ac_string

var _value: String = ""
var _validator: ac_validator

func _init(value: String = "", parent: ac_list = null, parent_key: Variant = null):
	_value = value
	_validator = get_validator().with(value)
	_parent = parent
	_parent_key = parent_key
	
func value():
	# Validate before returning the value
	if not _validator.check(_value):
		return _validator.source()
	return _value


func set_value(new_value: String):
	_value = new_value
	_validator.with(new_value)
	_notify_parent()

func duplicate() -> ac_string:
	# Create a duplicate with the same value and validator state
	return ac_string.new(_value)

func _get_validator() -> ac_validator:
	return preload("string_validator.gd").new()
