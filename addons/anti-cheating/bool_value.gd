extends ac_value
class_name ac_bool

var _value: bool = false
var _validator: ac_validator

func _init(value: bool = false, parent: ac_list = null, parent_key: Variant = null):
	_value = value
	_validator = get_validator().with(value)
	_parent = parent
	_parent_key = parent_key
	
func value():
	# Validate before returning the value
	if not _validator.check(_value):
		return _validator.source()
	return _value


func set_value(new_bool: bool):
	_value = new_bool
	_validator.with(new_bool)
	_notify_parent()

func duplicate() -> ac_bool:
	# Create a duplicate with the same value and validator state
	return ac_bool.new(_value)

func _get_validator() -> ac_validator:
	return preload("bool_validator.gd").new()
