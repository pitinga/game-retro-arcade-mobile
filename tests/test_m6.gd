extends SceneTree
const DeepData=preload("res://games/cave-rescue/levels.gd")
const EmeraldData=preload("res://games/jungle-expedition/rooms.gd")
const DeepModel=preload("res://games/cave-rescue/model.gd")
const EmeraldModel=preload("res://games/jungle-expedition/model.gd")
const Agent=preload("res://tests/m6_agents.gd")
const Session=preload("res://core/session.gd")
const View=preload("res://app/game_view.gd")
var failures: int=0
var rng:=RandomNumberGenerator.new()
func check(ok: bool,label: String) -> void:
	if not ok:
		failures+=1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func hash_state(s: RefCounted) -> String:
	var fields: Dictionary={}
	for p: Dictionary in s.model.get_property_list():
		if int(p.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE:
			fields[p.name]=s.model.get(p.name)
	var h:=HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(var_to_bytes([s.tick,s.rng.state,fields,s.get_result()]))
	return h.finish().hex_encode()
func replay(script: GDScript,fps: int,tape: Array[Dictionary]) -> String:
	var s:=Session.new()
	s.configure(script.new(),42,"normal")
	s.start()
	for input: Dictionary in tape:
		for frame in range(int(fps/30)):
			var snapshot:=input.duplicate(true)
			if fps>30 and frame!=(1 if fps==120 else 0):
				snapshot.erase("pressed")
			s.set_input(snapshot)
			s.advance(1.0/fps)
	return hash_state(s)
func run() -> void:
	var d:=DeepModel.new()
	var e:=EmeraldModel.new()
	for mode: String in ["easy","normal","hard"]:
		d.create(rng,mode)
		for level in range(1,21):
			d.level=level
			d.load_level()
			var rows: Array=DeepData.LEVELS[level-1]
			check(rows.size()==10,"M6-003 map height")
			var starts: int=0
			var rescues: int=0
			for row: String in rows:
				check(row.length()==26,"M6-003 map width")
				starts+=row.count("S")
				rescues+=row.count("R")
			check(starts==1 and rescues==1,"M6-003 unique start/rescue")
			for cell: Vector2i in d.hazards:
				check(not Rect2(Vector2(cell)*24,Vector2.ONE*24).intersects(d.hitbox(d.scientist)) and d.center(cell).distance_to(d.scientist)>=40,"M6-008 rescue clearance")
			var gates: int=0
			for cell: Vector2i in d.cells:
				if d.cells[cell]=="B":
					gates+=1
			check(gates<=d.charges,"AC-G06-02 cut budget "+str(level))
			check(not d.solid(d.pos) and not d.solid(d.scientist),"AC-G06-01 safe positions")
		e.create(rng,mode)
		for region in range(1,4):
			e.region=region
			var reachable: Dictionary={0:true}
			var queue: Array[int]=[0]
			var index: int=0
			while index<queue.size():
				for next: int in e.neighbors(queue[index]):
					if not reachable.has(next):
						reachable[next]=true
						queue.append(next)
				index+=1
			check(reachable.size()==8,"AC-G08-01 connected region "+str(region))
			for room in range(8):
				e.enter(room,36)
				var spec: Array=EmeraldData.ROOMS[(region-1)*8+room]
				check(spec.size()==3 and spec[0] in [0,1] and spec[2] in [0,1],"M6-003 valid room descriptor")
				check(e.gap.size.x==0 or (e.gap.position.x>=100 and e.gap.end.x<=540),"M6-003 gap inside field")
	d.create(rng,"normal")
	d.energy=0
	d.step({"fire":true},1.0/60,rng)
	check(d.vel.y>=0 and d.grace<1.5,"AC-G06-01 no jet at zero")
	d.batteries=[Vector2i(1,8)]
	d.step({},1.0/60,rng)
	check(d.energy>0 and d.grace==1.5,"AC-G06-01 grace recovery")
	var score:=d.score
	d.lose()
	d.batteries=[Vector2i(1,8)]
	d.step({},1.0/60,rng)
	check(d.score==score,"AC-G06-03 no duplicate battery")
	d.create(rng,"hard")
	d.level=2
	d.load_level()
	d.pos=Vector2(10*24-10,207)
	d.step({"pressed":{"secondary":Vector2.ZERO}},1.0/60,rng)
	check(d.charges==1 and d.cut_timer>0,"AC-G06-02 valid cut")
	d.pos.x-=65
	for tick in range(40):
		d.step({},1.0/60,rng)
	check(not d.cells.has(Vector2i(10,8)) and d.cells.has(Vector2i(10,7)),"AC-G06-02 cut only authorized tile")
	d.level=20
	d.load_level()
	d.pos=d.scientist
	var result: Dictionary={}
	for tick in range(36):
		result=d.step({"action":true},1.0/60,rng)
	check(result.get("reason","")=="victory","AC-G06-03 final victory")
	e.create(rng,"normal")
	e.bonus=0
	e.step({},1.0/60,rng)
	check(e.lives==3 and e.bonus==0,"AC-G08-03 bonus optional")
	e.enter(1,550)
	e.step({},1.0/60,rng)
	check(e.count_region()==1 and e.score==350,"AC-G08-03 artifact")
	e.lose()
	e.enter(1,550)
	e.step({},1.0/60,rng)
	check(e.count_region()==1 and e.score==350 and e.lives==2,"AC-G08-03 no duplicate artifact")
	e.enter(0,36)
	e.step({"action":true},1.0/60,rng)
	check(e.region==1,"AC-G08-01 locked exit")
	e.create(rng,"normal")
	e.step({"pressed":{"fire":Vector2.ZERO}},1.0/60,rng)
	check(e.vel.y<0 and e.buffer==0 and not e.grounded,"AC-G08-02 jump")
	e.enter(4,320)
	for tick in range(120):
		e.step({"action":true,"up":true},1.0/60,rng)
		if e.room==0: break
	check(e.room==0,"AC-G08-02 climb transition")
	e.enter(0,320)
	e.step({"down":true},1.0/60,rng)
	check(e.room==0 and e.ladder_progress>0,"M6-005 descent not instant")
	for tick in range(120):
		e.step({"down":true},1.0/60,rng)
		if e.room==4: break
	check(e.room==4,"M6-005 descent completes")
	e.enter(4,80)
	e.step({"action":true},1.0/60,rng)
	check(e.checkpoint_set,"M6-005 checkpoint active")
	e.lose()
	check(e.room==4 and is_equal_approx(e.pos.x,80),"M6-005 checkpoint respawn")
	var deep_ok: int=0
	var emerald_ok: int=0
	for mode: String in ["easy","normal","hard"]:
		d.create(rng,mode)
		var agent:=Agent.new()
		var completed: bool=false
		var initial_lives:=d.lives
		for tick in range(72000):
			result=d.step(agent.deep_input(d),1.0/60,rng)
			if not result.is_empty():
				completed=result.get("reason","")=="victory"
				break
		deep_ok+=int(completed and d.lives==initial_lives)
		print("DEEP CAMPAIGN ",mode," level=",d.level," lives=",d.lives," won=",completed)
		e.create(rng,mode)
		initial_lives=e.lives
		completed=false
		for tick in range(108000):
			result=e.step(agent.emerald_input(e),1.0/60,rng)
			if not result.is_empty():
				completed=result.get("reason","")=="victory"
				break
		emerald_ok+=int(completed and e.lives==initial_lives)
		print("EMERALD CAMPAIGN ",mode," region=",e.region," room=",e.room," artifacts=",e.collected.size()," lives=",e.lives," won=",completed)
	print("DEEP CAMPAIGN SUMMARY ",deep_ok,"/3")
	print("EMERALD CAMPAIGN SUMMARY ",emerald_ok,"/3")
	check(deep_ok==3,"AC-G06 live campaign")
	check(emerald_ok==3,"AC-G08 live campaign")
	for script: GDScript in [DeepModel,EmeraldModel]:
		var s:=Session.new()
		s.configure(script.new(),42,"normal")
		s.start()
		s.pause()
		s.advance(3)
		check(s.tick==0,"M6 pause")
		s.resume()
		var tape: Array[Dictionary]=[]
		var agent:=Agent.new()
		for block in range(3600):
			var input: Dictionary=agent.deep_input(s.model) if script==DeepModel else agent.emerald_input(s.model)
			tape.append(input)
			s.set_input(input)
			s.advance(2.0/60)
			if s.state!=Session.State.RUNNING:
				break
		var hash:=replay(script,60,tape)
		check(hash==replay(script,30,tape) and hash==replay(script,120,tape),"M6 replay "+script.resource_path)
		print("REPLAY ",script.resource_path," ",hash)
	for id: String in ["G06","G08"]:
		var view:=View.new()
		view.configure(id,"normal","pt",{},42)
		root.add_child(view)
		await process_frame
		check(view.landscape and view.host.session.state==Session.State.PAUSED,"M6 view "+id)
		view.queue_free()
		await process_frame
	var app: Control=(load("res://app/main.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await process_frame
	for id: String in ["G06","G08"]:
		app.call("_start_game",id)
		check(app.page=="details","M6 production PRO locked")
	app.queue_free()
	await process_frame
	print("M6 failures: ",failures)
	quit(1 if failures else 0)
