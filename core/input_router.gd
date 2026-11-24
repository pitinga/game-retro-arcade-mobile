extends RefCounted
# Pointer ID captures action, origin and position until release/cancel.
var _owners: Dictionary = {}
var _keyboard: Dictionary = {}
var _edges: Dictionary = {}
func press(pointer: int, action: String, position: Vector2 = Vector2.ZERO) -> bool:
	if _owners.has(pointer) or action.is_empty():
		return false
	_owners[pointer] = {"action":action,"origin":position,"position":position}
	_edges[action] = position
	return true
func drag(pointer: int, position: Vector2) -> void:
	if _owners.has(pointer):
		_owners[pointer].position = position
func release(pointer: int, canceled: bool = false) -> void:
	if canceled and _owners.has(pointer):
		_edges.erase(_owners[pointer].action)
	_owners.erase(pointer)
func key(action: String, down: bool) -> void:
	if down:
		if not _keyboard.has(action):
			_edges[action] = Vector2.ZERO
		_keyboard[action] = true
	else:
		_keyboard.erase(action)
func snapshot() -> Dictionary:
	var result := _keyboard.duplicate()
	var analog: Dictionary = {}
	var ids := _owners.keys()
	ids.sort()
	for id: int in ids:
		var p: Dictionary = _owners[id]
		var action: String = p.action
		result[action] = true
		if not analog.has(action):
			analog[action] = {"id":id,"position":p.position,"origin":p.origin,"delta":p.position-p.origin}
	if not analog.is_empty():
		result["analog"] = analog
	if not _edges.is_empty():
		result["pressed"] = _edges.duplicate()
	return result
func consume_edges() -> void:
	_edges.clear()
func clear() -> void:
	_owners.clear()
	_keyboard.clear()
	_edges.clear()
