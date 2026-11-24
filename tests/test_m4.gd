extends SceneTree
const Abyss=preload("res://games/submarine-rescue/model.gd")
const Polar=preload("res://games/ice-platformer/model.gd")
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
func replay(script: GDScript,fps: int) -> String:
	var s:=Session.new()
	s.configure(script.new(),42,"normal")
	s.start()
	for frame in range(fps*12):
		s.set_input({"right":true,"down":true,"fire":true,"action":true})
		s.advance(1.0/fps)
	var fields: Dictionary={}
	for prop: Dictionary in s.model.get_property_list():
		if int(prop.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE:
			fields[prop.name]=s.model.get(prop.name)
	var h:=HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(var_to_bytes([s.tick,s.rng.state,fields,s.get_result()]))
	return h.finish().hex_encode()
func run() -> void:
	rng.seed=42
	var a:=Abyss.new()
	a.create(rng,"normal")
	a.step({"right":true,"down":true,"fire":true},1.0/60,rng)
	check(is_equal_approx((a.velocity/Vector2(0.48*Abyss.W,0.65*Abyss.H)).length(),1),"AC-G04-01 normalized")
	check(a.shots.size()==1 and a.shots[0].vx>0,"AC-G04-01 pulse")
	a.step({"fire":true},1.0/60,rng)
	check(a.shots.size()==1,"AC-G04-01 cooldown")
	a.pos=Vector2(320,120)
	a.capsules=[{"id":1,"pos":a.pos}]
	a.enemies.clear()
	a.step({},1.0/60,rng)
	check(a.cargo==1 and a.capsules.is_empty(),"AC-G04-01 collect once")
	a.step({},1.0/60,rng)
	check(a.cargo==1,"AC-G04-01 no repeat")
	a.cargo=a.capacity()
	a.capsules=[{"id":2,"pos":a.pos}]
	a.step({},1.0/60,rng)
	check(a.cargo==a.capacity() and a.capsules.size()==1,"AC-G04-01 cap")
	a.pos=Vector2(320,15)
	a.oxygen=40
	a.cargo=0
	var old_score:=a.score
	a.step({},1.0/60,rng)
	check(a.oxygen>40 and a.score==old_score,"AC-G04-02 refill no penalty")
	a.cargo=4
	a.delivered=4
	a.step({},1.0/60,rng)
	check(a.wave==2 and a.delivered==2 and a.cargo==0 and a.score==950,"AC-G04-02 delivery carry")
	a.create(rng,"normal")
	a.pos=Vector2(320,100)
	a.oxygen=0
	a.cargo=3
	a.step({},1.0/60,rng)
	check(a.lives==2 and a.cargo==0 and a.oxygen==100,"AC-G04-03 oxygen death")
	a.lives=1
	a.oxygen=0
	a.pos=Vector2(320,100)
	check(not a.step({},1.0/60,rng).is_empty(),"AC-G04-03 terminal")
	for seed in range(1000):
		rng.seed=seed
		a.create(rng,["easy","normal","hard"][seed%3])
		check(a.capsules.size()>0 and a.capsules.size()<=6 and a.enemies.size()<=8,"AC-G04-04 caps")
		var c: Vector2=a.capsules[0].pos
		var trip:=2*(absf(c.x-a.pos.x)/(0.48*Abyss.W)+absf(c.y-a.pos.y)/(0.65*Abyss.H))
		check(trip*7<100 and c.y<0.45*Abyss.H,"AC-G04-04 shallow return budget")
		for e: Dictionary in a.enemies:
			check(e.pos.y>=0.18*Abyss.H,"AC-G04-04 safe surface")
	var p:=Polar.new()
	p.create(rng,"normal")
	var start:=p.pos
	p.step({"right":true},1.0/60,rng)
	check(p.pos==start and p.jump_left==0,"AC-G05-01 no movement without jump")
	p.step({"right":true,"pressed":{"fire":Vector2.ZERO}},1.0/60,rng)
	check(p.jump_left>0 and p.support==-1,"AC-G05-01 jump")
	p.create(rng,"normal")
	for tick in range(30):
		p.step({"action":true},1.0/60,rng)
	check(not p.repaired[0],"AC-G05-02 not yet repaired")
	p.step({},1.0/60,rng)
	check(p.repair_time==0,"AC-G05-02 interruption")
	for tick in range(60):
		p.step({"action":true},1.0/60,rng)
	check(p.repaired[0] and p.score==180,"AC-G05-02 repair")
	p.lose()
	check(p.repaired[0] and p.score==80 and p.lives==2,"AC-G05-03 persistent repair penalty")
	p.create(rng,"normal")
	for station in range(3):
		p.pos=p.stations[station]
		for tick in range(60):
			p.step({"action":true},1.0/60,rng)
	check(p.phase==2 and p.score==1140,"AC-G05-02 phase unique reward")
	p.create(rng,"hard")
	p.pos=Vector2(10,10)
	p.jump_left=0.001
	p.jump_from=p.pos
	p.jump_to=p.pos
	p.step({},1.0/60,rng)
	check(p.lives==1,"AC-G05-01 water fatal")
	p.energy=50
	p.pos=p.stations[0]
	p.step({},1.0/60,rng)
	check(p.energy>50,"AC-G05-03 recharge")
	for seed in range(1000):
		rng.seed=seed
		p.create(rng,["easy","normal","hard"][seed%3])
		check(p.platforms.size()==18 and p.stations.size()==3,"AC-G05-04 platform count")
		for platform: Dictionary in p.platforms:
			check(Rect2(0,0,Polar.W,Polar.H).has_point(platform.pos),"AC-G05-04 bounds")
	# Actual simulation pause for both modules.
	for script: GDScript in [Abyss,Polar]:
		var s:=Session.new()
		s.configure(script.new(),42,"normal")
		s.start()
		s.pause()
		s.advance(2)
		check(s.tick==0,"M4 pause "+script.resource_path)
		var hash:=replay(script,60)
		check(hash==replay(script,30) and hash==replay(script,120),"M4 replay "+script.resource_path)
		print("REPLAY ",script.resource_path," ",hash)
	for id: String in ["G04","G05"]:
		var view:=View.new()
		view.configure(id,"normal","pt",{},42)
		root.add_child(view)
		view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await process_frame
		check(view.landscape and view.host.session.state==Session.State.PAUSED,"M4 view "+id)
		view.queue_free()
		await process_frame
	var app: Control=(load("res://app/main.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await process_frame
	for id: String in ["G04","G05"]:
		app.call("_start_game",id)
		check(app.page=="details","M4 production PRO locked "+id)
	app.queue_free()
	await process_frame
	print("M4 failures: ",failures)
	quit(1 if failures else 0)
