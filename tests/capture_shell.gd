extends SceneTree
var app: Control
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("capture empty")
		quit(1)
		return
	var result := image.save_png("res://build/screenshots/"+name+".png")
	if result != OK:
		push_error("capture failed: "+name)
		quit(1)
func run() -> void:
	var scene := load("res://app/main.tscn") as PackedScene
	app = scene.instantiate()
	root.add_child(app)
	for dims: Vector2i in [Vector2i(360,640),Vector2i(360,800),Vector2i(411,890)]:
		root.size = dims
		await process_frame
		var tag := str(dims.x)+"x"+str(dims.y)
		app.call("_catalog")
		await snap(tag+"-catalog")
		app.call("_details","G04")
		await snap(tag+"-locked")
		app.call("_upgrade")
		await snap(tag+"-pro")
		app.call("_settings")
		await snap(tag+"-settings")
	app.queue_free()
	await process_frame
	quit(0)
