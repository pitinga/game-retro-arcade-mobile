extends SceneTree
const Agent=preload("res://tests/m6_agents.gd")
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
	for id: String in ["G06","G08"]:
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
			for tick in range(2400):
				var input: Dictionary=agent.deep_input(view.model) if id=="G06" else agent.emerald_input(view.model)
				view.host.session.set_input(input)
				view.host.session.advance(1.0/60)
				if id=="G06" and view.model.level==2 and view.model.cut_timer>0:
					break
				if id=="G08" and view.model.room==1 and not view.model.grounded:
					break
			if (id=="G06" and (view.model.level!=2 or view.model.cut_timer<=0)) or (id=="G08" and (view.model.room!=1 or view.model.grounded)):
				push_error("M6 live capture state not reached "+id)
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
			# Explicit visual fixtures: not evidence of a completed live route.
			view._resume()
			if id=="G06":
				view.model.level=20
				view.model.load_level()
				view.model.time=2.1
				view.queue_redraw()
				if not await snap(tag+"-vapor-warning-fixture"):
					quit(1)
					return
				view.model.time=3.1
				view.queue_redraw()
				if not await snap(tag+"-vapor-active-fixture"):
					quit(1)
					return
			else:
				view.model.enter(0,320)
				view.model.climbing=true
				view.model.ladder_progress=0.5
				view.model.pos.y=127
				view.queue_redraw()
				if not await snap(tag+"-ladder-fixture"):
					quit(1)
					return
				view.model.enter(1,360)
				view.model.pos.x=view.model.bridge_x
				view.model.on_bridge=true
				view.model.collapse=0.9
				view.queue_redraw()
				if not await snap(tag+"-bridge-warning-fixture"):
					quit(1)
					return
			view._on_result({"score":12345,"reason":"victory","progress":20 if id=="G06" else 3})
			if not await snap(tag+"-victory-fixture"):
				quit(1)
				return
			root.remove_child(view)
			view.queue_free()
			await process_frame
	quit(0)
