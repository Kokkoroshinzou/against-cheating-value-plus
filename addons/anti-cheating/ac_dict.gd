extends RefCounted
class_name ac_dict

# The number of times interference data is generated; the higher the value, the lower the performance, but the better the effect.
var disturb: int = 0

# Private
var _pool: Dictionary = {}
var _disturb_threads: Dictionary = {}  # Map threads to their values
var _pool_mutex: Mutex = Mutex.new()   # Mutex for _pool
var _disturb_queue: Array = []          # Queue to manage disturbance tasks

func set_value(key: String, value: ac_value):
	_pool_mutex.lock()
	if !_pool.is_empty() and _pool.has(key):
		await _quieten(_pool[key])
	_pool[key] = value
	_pool_mutex.unlock()
	# Add disturbance task to the queue
	_disturb_queue.append(value)
	_process_disturbance_queue()

func get_value(key: String, default_value: ac_value = ac_value.new()) -> ac_value:
	return _pool[key] if _pool.has(key) else default_value

func has(key: String) -> bool:
	_pool_mutex.lock()
	var result = _pool.has(key)
	_pool_mutex.unlock()
	return result

func keys() -> Array[String]:
	var result = _pool.keys()
	return result

func erase(key: String) -> bool:
	_pool_mutex.lock()
	_silence(_pool[key])
	var result = _pool.erase(key)
	_pool_mutex.unlock()
	return result

func clear():
	_pool_mutex.lock()
	_pool.clear()
	_pool_mutex.unlock()

func is_empty() -> bool:
	return _pool.is_empty()

# Process disturbances in the queue, ensuring only one is handled at a time
func _process_disturbance_queue():
	if _disturb_threads.size() < 10 and _disturb_queue.size() > 0:  # Arbitrary limit
		var value = _disturb_queue.pop_front()
		_do_disturb(value)

func _do_disturb(value: ac_value):
	if _disturb_threads.has(value):  # Prevent duplicate interference for the same value
		print("Disturb already active for value: ", value)
		return
	if _disturb_threads.size() >= 10:  # Arbitrary limit
		print("Pool Size: ", _pool.size(), ". Too many disturbance threads running, skipping...")
		return

	var thread = Thread.new()
	_disturb_threads[value] = thread
	thread.start(_background_disturb.bind([thread, value]))

func _background_disturb(params: Array) -> void:
	var thread: Thread = params[0]
	var value: ac_value = params[1]

	for i in range(disturb):
		_pool_mutex.lock()
		var salt = generate_salt()
		_pool["__ac_disturb:%d__" % i + salt] = value.duplicate()
		_pool_mutex.unlock()

	# Notify completion
	_on_disturb_complete.call_deferred(thread)

func _on_disturb_complete(thread: Thread):
	# Clean up the thread and process the next disturbance
	if _disturb_threads.has(thread):
		thread.wait_to_finish()
		_disturb_threads.erase(thread)
		print("Pool Size: " + str(_pool.size()) + ". Disturbance thread completed and cleaned up.")
	_process_disturbance_queue()  # Start the next disturbance if there are tasks in the queue

func generate_salt() -> String:
	var rng = RandomNumberGenerator.new()
	var salt = ""
	for i in range(8):  # Generate an 8-character salt
		salt += String(char(rng.randi_range(65, 90)))  # Convert ASCII to a character
	return salt

func _quieten(value):
	_pool_mutex.lock()
	var to_remove = []
	var count = 0
	for wave in _pool:
		if wave.begins_with("__ac_disturb") and _pool.has(wave) and _pool[wave] == value:
			if count > disturb:
				to_remove.append(wave)
				count+=1
			else:
				count+=1
	for key in to_remove:
		_pool.erase(key)
	_pool_mutex.unlock()
	
func _silence(value):
	var to_remove = []
	for wave in _pool:
		if _pool[wave] == value and wave.begins_with("__ac_disturb"):
			to_remove.append(wave)
	for horse in to_remove:
		_pool.erase(horse)
	
