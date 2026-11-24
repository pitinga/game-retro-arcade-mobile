extends Node
# Lifecycle/input adapter. Games supply non-overlapping touch areas in logical coords.
const Session = preload("res://core/session.gd")
const Router = preload("res://core/input_router.gd")
const Layout = preload("res://core/layout.gd")
var session := Session.new()
var router := Router.new()
var fitted: Dictionary = {"rect":Rect2(),"scale":0.0}
var touch_regions: Dictionary = {}
signal paused
signal finished(result: Dictionary)

func configure(module: RefCounted, seed_value: int, difficulty: String) -> bool:
	return session.configure(module,seed_value,difficulty)
func configure_layout(safe: Rect2, landscape: bool, regions: Dictionary) -> void:
	router.clear()
	fitted = Layout.fit(safe,landscape)
	touch_regions = regions.duplicate(true)
func start() -> bool:
	return session.start()
func pause_game() -> void:
	router.clear()
	if session.state == Session.State.RUNNING:
		session.pause()
		paused.emit()
func resume_game() -> bool:
	router.clear()
	return session.resume()
func advance_game(delta: float) -> void:
	if session.state != Session.State.RUNNING:
		return
	session.set_input(router.snapshot())
	if session.advance(delta) > 0:
		router.consume_edges()
	if session.state == Session.State.RESULT:
		router.clear()
		finished.emit(session.get_result())
func _process(delta: float) -> void:
	advance_game(delta)
func route_touch(pointer: int, point: Vector2, pressed: bool, canceled: bool = false) -> void:
	if not pressed or canceled:
		router.release(pointer,canceled)
		return
	if session.state != Session.State.RUNNING:
		return
	var logical: Variant = Layout.logical_point(point,fitted)
	if logical == null:
		return
	for action: String in touch_regions:
		var area: Rect2 = touch_regions[action]
		if area.has_point(logical):
			router.press(pointer,action,logical)
			return
func route_drag(pointer: int, point: Vector2) -> void:
	if session.state != Session.State.RUNNING or fitted.scale <= 0.0:
		return
	var rect: Rect2 = fitted.rect
	# Captured drag stays owned even outside the original region; clamp to field.
	var local := (point-rect.position)/float(fitted.scale)
	var bounds := rect.size/float(fitted.scale)
	router.drag(pointer,local.clamp(Vector2.ZERO,bounds))
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		route_touch(event.index,event.position,event.pressed,event.canceled)
	elif event is InputEventScreenDrag:
		route_drag(event.index,event.position)
	elif event is InputEventKey and not event.echo:
		if event.keycode == KEY_ESCAPE and event.pressed:
			pause_game()
			return
		var keys := {KEY_LEFT:"left",KEY_A:"left",KEY_RIGHT:"right",KEY_D:"right",KEY_UP:"up",KEY_W:"up",KEY_DOWN:"down",KEY_S:"down",KEY_SPACE:"fire",KEY_Z:"action",KEY_X:"secondary"}
		if keys.has(event.keycode) and session.state == Session.State.RUNNING:
			# keyboard keys own distinct pointers, allowing aliases to overlap
			var owner := -int(event.keycode)-1
			if event.pressed:
				router.press(owner,keys[event.keycode])
			else:
				router.release(owner)
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_GO_BACK_REQUEST]:
		pause_game()
func _exit_tree() -> void:
	router.clear()
	session.dispose()
