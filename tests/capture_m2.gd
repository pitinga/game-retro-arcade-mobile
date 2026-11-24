extends SceneTree
const View=preload("res://app/game_view.gd")
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> bool:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	return image!=null and not image.is_empty() and image.save_png("res://build/screenshots/"+name+".png")==OK
func run() -> void:
	for id: String in ["G03","G09","G10"]:
		for dims: Vector2i in ([Vector2i(360,640),Vector2i(360,800)] if id=="G03" else [Vector2i(640,360),Vector2i(800,360)]):
			root.size=dims
			var view:=View.new()
			view.configure(id,"normal","pt")
			root.add_child(view)
			view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			await process_frame
			view._resume()
			view.host.set_process(false)
			for tick in range(180):
				var input: Dictionary={}
				if id=="G03" and tick==60:
					input={"pressed":{"fire":Vector2.ZERO}}
				elif id=="G09":
					input={"fire":true,"up":true,"right":tick<50}
				elif id=="G10" and tick in [60,120]:
					input={"pressed":{"aim":Vector2(170+tick,160)}}
				view.host.session.set_input(input)
				view.host.session.advance(1.0/60.0)
			view.queue_redraw()
			var tag:=id+"-"+str(dims.x)+"x"+str(dims.y)
			if not await snap(tag+"-game"):
				push_error("capture "+tag)
				quit(1)
				return
			view.pause_game()
			if not await snap(tag+"-pause"):
				quit(1)
				return
			root.remove_child(view)
			view.queue_free()
			await process_frame
	quit(0)
