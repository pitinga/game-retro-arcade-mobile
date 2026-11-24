extends SceneTree
const Agent=preload("res://tests/m5_agent.gd")
const View=preload("res://app/game_view.gd")
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> bool:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	if image==null or image.is_empty():
		return false
	var palette: Dictionary={}
	for y in range(0,image.get_height(),4):
		for x in range(0,image.get_width(),4):
			palette[image.get_pixel(x,y).to_rgba32()]=true
			if palette.size()>=12:
				return image.save_png("res://build/screenshots/"+name+".png")==OK
	return false
func run() -> void:
	for id: String in ["G07"]:
		for dims: Vector2i in [Vector2i(640,360),Vector2i(800,360)]:
			root.size=dims
			var view:=View.new()
			view.configure(id,"normal","pt",{},42)
			root.add_child(view)
			view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			await process_frame
			view._resume()
			view.host.set_process(false)
			var agent:=Agent.new()
			for tick in range(3000):
				view.host.session.set_input(agent.input_for(view.model))
				view.host.session.advance(1.0/60)
				if view.model.active_count==2:
					break
			if view.model.active_count!=2:
				push_error("M5 capture did not reach blocker state")
				quit(1)
				return
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
			# Explicit deterministic visual fixture for late warning (not a live agent proof).
			view._resume()
			view.model.remaining=14
			view.model.exit_revealed=true
			view.model.door_warning=true
			view.model.conveyor_warning=true
			view.queue_redraw()
			if not await snap(tag+"-warning-fixture"):
				quit(1)
				return
			root.remove_child(view)
			view.queue_free()
			await process_frame
	quit(0)
