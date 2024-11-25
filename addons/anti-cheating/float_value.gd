extends ac_value
class_name ac_float

var _value: float
var _validator: ac_validator
	
func _init(v: float = 0, parent: ac_list = null, parent_key: Variant = null) -> void:
	_value = v
	_validator = get_validator().with(v)
	_parent = parent
	_parent_key = parent_key
		
func value():
	if not _validator.check(_value):
		return _validator.source()
	return _value
	
func set_value(v: float):
	_value = v
	_validator.with(v)
	_notify_parent()
	
# override
func _get_validator() -> ac_validator:
	return preload("float_validator.gd").new()
	
# override
func duplicate() -> ac_value:
	return ac_float.new(_value)
	
