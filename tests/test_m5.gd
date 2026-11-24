extends SceneTree
const SkyModel=preload("res://games/terminal-chase/model.gd")
const Agent=preload("res://tests/m5_agent.gd")
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
func replay(fps: int,tape: Array[Dictionary]) -> String:
	var s:=Session.new()
	s.configure(SkyModel.new(),42,"normal")
	s.start()
	for input: Dictionary in tape:
		for frame in range(int(fps/30)):
			var snapshot:=input.duplicate(true)
			if fps>30 and frame!=(1 if fps==120 else 0):
				snapshot.erase("pressed")
			s.set_input(snapshot)
			s.advance(1.0/fps)
	var fields: Dictionary={}
	for p: Dictionary in s.model.get_property_list():
		if int(p.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE:
			fields[p.name]=s.model.get(p.name)
	var h:=HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(var_to_bytes([s.tick,s.rng.state,fields,s.get_result()]))
	return h.finish().hex_encode()
func run() -> void:
	var m:=SkyModel.new()
	m.create(rng,"normal")
	m.player=m.robot
	m.step({},1.0/60,rng)
	check(m.round==1 and m.score==0 and m.contact_hint>0,"AC-G07-01 locked contact")
	m.player=m.node(m.ZONES[0])
	for tick in range(36):
		m.step({"action":true},1.0/60,rng)
	check(m.active_count==1,"AC-G07-01 first blocker")
	m.player=m.node(m.ZONES[1])
	for tick in range(36):
		m.step({"action":true},1.0/60,rng)
	check(m.active_count==2,"AC-G07-01 second distinct blocker")
	m.player=m.robot
	m.step({},1.0/60,rng)
	check(m.round==2 and m.score>=450,"AC-G07-04 capture once")
	m.create(rng,"normal")
	m.player=m.node(m.ZONES[0])
	m.stun=0.45
	m.step({"action":true},1.0/60,rng)
	check(m.progress==0,"M5 self-review stunned interaction blocked")
	m.remaining=15.0
	m.step({},1.0/60,rng)
	check(m.exit_revealed,"M5 self-review exit warning")
	m.round=2
	var old_score:=m.score
	m.remaining=0.001
	var lives:=m.lives
	m.step({},1.0/60,rng)
	check(m.lives==lives-1 and m.score==old_score and m.round==2,"AC-G07-04 timeout")
	m.create(rng,"normal")
	m.step({"pressed":{"secondary":Vector2.ZERO},"right":true},1.0/60,rng)
	check(m.dash_cd==5 and m.dash_left==0.25,"AC-G07-03 dash")
	m.step({"pressed":{"secondary":Vector2.ZERO}},1.0/60,rng)
	check(m.dash_cd<5 and m.dash_left<0.25,"AC-G07-03 no double dash")
	m.create(rng,"normal")
	m.player=Vector2(545,213)
	m.drones=[{"pos":m.player,"phase":0.0,"row":2}]
	var timer:=m.remaining
	m.step({},1.0/60,rng)
	check(m.stun>0 and m.immune>0 and timer-m.remaining>5,"AC-G07-03 drone penalty")
	timer=m.remaining
	m.step({},1.0/60,rng)
	check(timer-m.remaining<0.1,"AC-G07-03 i-frame single penalty")
	m.create(rng,"normal")
	m.remaining=5
	m.robot_to=m.exit_id
	m.robot=m.node(m.exit_id)
	lives=m.lives
	m.step({},1.0/60,rng)
	check(m.lives==lives-1 and m.score==0,"AC-G07-04 escape")
	m.create(rng,"normal")
	m.door_closed=true
	for seed in range(1000):
		rng.seed=seed
		m.create(rng,["easy","normal","hard"][seed%3])
		m.door_closed=true
		for from in range(12):
			for goal: int in m.ZONES:
				check(not m.path(from,goal).is_empty(),"AC-G07-02 connected "+str(seed))
		for wall: Rect2 in m.walls:
			check(m.blocked(wall.get_center()),"AC-G07-03 solid")
	var ok: int=0
	var naive_fail: int=0
	for seed in range(12):
		rng.seed=seed
		m.create(rng,["easy","normal","hard"][seed%3])
		var agent:=Agent.new()
		var initial_lives:=m.lives
		for tick in range(4800):
			var result:=m.step(agent.input_for(m),1.0/60,rng)
			if m.round>1 or not result.is_empty():
				break
		if m.round>1 and m.lives==initial_lives:
			ok+=1
		print("SKYPORT AGENT seed=",seed," round=",m.round," lives=",m.lives)
			rng.seed=seed
		m.create(rng,["easy","normal","hard"][seed%3])
		initial_lives=m.lives
		var naive:=Agent.new()
		naive.pursuit_only=true
		for tick in range(4800):
			var result:=m.step(naive.input_for(m),1.0/60,rng)
			if m.lives<initial_lives or not result.is_empty():
				break
		if m.lives<initial_lives and m.round==1 and m.score==0:
			naive_fail+=1
	print("SKYPORT AGENT SUMMARY ",ok,"/12")
	print("SKYPORT NAIVE SUMMARY ",naive_fail,"/12")
	check(naive_fail==12,"M5-003 naive pursuit must lose life")
	check(ok==12,"AC-G07-02 representative live agent")
	# Multiple later rounds with real movement and unchanged life count.
	var later_ok: int=0
	for seed in range(3):
		rng.seed=seed+100
		m.create(rng,["easy","normal","hard"][seed])
		var initial_lives:=m.lives
		var late_agent:=Agent.new()
		for tick in range(15000):
			var result:=m.step(late_agent.input_for(m),1.0/60,rng)
			if m.round>=4 or not result.is_empty() or m.lives<initial_lives:
				break
		later_ok+=int(m.round>=4 and m.lives==initial_lives)
		print("SKYPORT LATER seed=",seed," round=",m.round," lives=",m.lives)
	print("SKYPORT LATER SUMMARY ",later_ok,"/3")
	check(later_ok==3,"M5-003 three rounds without life loss")
	m.create(rng,"normal")
	m.player=Vector2(65,83)
	m.dash_left=0.25
	m.last_axis=Vector2.RIGHT
	for tick in range(15):
		m.step({"right":true},1.0/60,rng)
		check(not m.blocked(m.player),"M5-003 dash cannot enter wall")
	var s:=Session.new()
	s.configure(SkyModel.new(),42,"normal")
	s.start()
	s.pause()
	var frozen: float=s.model.remaining
	s.advance(5)
	check(s.model.remaining==frozen and s.tick==0,"AC-G07-03 pause")
	s.resume()
	var agent:=Agent.new()
	var tape: Array[Dictionary]=[]
	var saw_dash: bool=false
	var saw_door: bool=false
	for block in range(2400):
		var input: Dictionary={}
		if block>=210:
			input=agent.input_for(s.model)
		if block==30:
			input={"right":true,"pressed":{"secondary":Vector2.ZERO}}
		tape.append(input)
		s.set_input(input)
		s.advance(2.0/60)
		saw_dash=saw_dash or s.model.dash_cd>0
		saw_door=saw_door or s.model.door_closed
		if s.state!=Session.State.RUNNING:
			break
	check(s.model.round>1 and s.model.score>0,"M5 replay meaningful capture")
	check(s.model.round>1 and s.model.score>0,"M5-003 real replay capture")
	check(saw_dash and saw_door,"M5-003 replay dash and door")
	var hash:=replay(60,tape)
	check(hash==replay(30,tape) and hash==replay(120,tape),"M5 replay")
	print("REPLAY res://games/terminal-chase/model.gd ",hash)
	var view:=View.new()
	view.configure("G07","normal","pt",{},42)
	root.add_child(view)
	await process_frame
	check(view.landscape and view.host.session.state==Session.State.PAUSED,"M5 view")
	view.queue_free()
	await process_frame
	var app: Control=(load("res://app/main.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await process_frame
	app.call("_start_game","G07")
	check(app.page=="details","M5 production PRO locked")
	app.queue_free()
	await process_frame
	print("M5 failures: ",failures)
	quit(1 if failures else 0)
