extends RefCounted
# Pointer ID owns an action until release; one action may have multiple owners.
var _owners: Dictionary = {}
var _keyboard: Dictionary = {}
func press(pointer: int, action: String) -> bool:
	if _owners.has(pointer) or action.is_empty():
		return false
	_owners[pointer] = action
	return true
func release(pointer: int) -> void:
	_owners.erase(pointer)
func key(action: String, down: bool) -> void:
	if down:
		_keyboard[action] = true
	else:
		_keyboard.erase(action)
func snapshot() -> Dictionary:
	var result := _keyboard.duplicate()
	for action: String in _owners.values():
		result[action] = true
	return result
func clear() -> void:
	_owners.clear()
	_keyboard.clear()
