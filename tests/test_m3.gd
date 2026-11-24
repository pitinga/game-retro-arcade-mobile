extends SceneTree
const River=preload("res://games/river-shooter/model.gd")
const Rally=preload("res://games/endurance-racing/model.gd")
const Session=preload("res://core/session.gd")
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
	for frame in range(fps*(180 if script==River else 10)):
		var segment:=int(float(frame)/fps/2.0)%3
		s.set_input({"up":true,"fire":true,"left":segment==0,"right":segment==1})
		s.advance(1.0/fps)
	var fields: Dictionary={}
	for prop: Dictionary in s.model.get_property_list():
		if int(prop.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE:
			fields[prop.name]=s.model.get(prop.name)
	var h:=HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(var_to_bytes([s.tick,s.rng.state,fields,s.get_result()]))
	return h.finish().hex_encode()
func agent_lane(a: RefCounted) -> float:
	var nearest: Dictionary={}
	for car: Dictionary in a.rivals:
		if car.z>=-5 and (nearest.is_empty() or car.z<nearest.z):
			nearest=car
	if nearest.is_empty():
		return a.lateral
	var used: Dictionary={}
	for car: Dictionary in a.rivals:
		if car.get("group",-1)==nearest.get("group",-1):
			used[int(car.get("target",car.lane))]=true
	for lane in range(3):
		if not used.has(lane):
			return a.lanes[lane]
	return a.lateral
func run() -> void:
	var r:=River.new()
	for seed in range(1000):
		rng.seed=seed
		r.create(rng,["easy","normal","hard"][seed%3])
		r.sector=3
		r.generate_sector(rng,180)
		for i in range(r.centers.size()-1):
			check(absf(r.centers[i+1]-r.centers[i])<=36.001 and r.widths[i]>=0.32*River.W,"AC-G01-01 continuous lane")
		var last: float=0
		for o: Dictionary in r.objects:
			if o.kind=="energy":
				check(absf(float(o.x)-r.corridor(o.z).x)<=r.corridor(o.z).y/2-River.R and float(o.z)-last<=0.73*River.H,"AC-G01-01 reachable cell interval")
				last=o.z
		check(r.length-last<=0.73*River.H,"AC-G01-01 final energy interval")
	r.create(rng,"normal")
	r.sector=3
	r.generate_sector(rng,180)
	var before_lives:=r.lives
	for tick in range(3600):
		var desired:=r.corridor(r.distance).x
		r.step({"left":r.x>desired+5,"right":r.x<desired-5},1.0/60,rng)
		if r.lives<before_lives:
			break
	check(r.lives<before_lives,"M3-002 central autopilot loses life")
	r.create(rng,"normal")
	r.points(8000)
	check(r.lives==4,"M3-004 bonus life")
	r.energy=100
	r.step({"up":true},1.0/60,rng)
	check(r.energy<100-5.0/60,"M3-004 boost drain")
	r.immune=0
	r.x=-100
	r.energy=0
	var old_lives:=r.lives
	r.step({},1.0/60,rng)
	check(r.lives==old_lives-1 and r.distance==0 and r.energy==100,"M3-004 simultaneous death/respawn")
	r.create(rng,"normal")
	r.energy=95
	var cell: Dictionary=r.objects[0]
	r.collect(cell)
	r.collect(cell)
	check(r.energy==100 and r.score==20,"AC-G01-02 saturate and no repeat")
	r.lose()
	r.collect(cell)
	check(r.score==20,"AC-G01-03 checkpoint no score farm")
	r.energy=0
	r.lives=1
	check(not r.step({},1.0/60,rng).is_empty() and r.lives==0,"AC-G01-03 energy terminal")
	r.create(rng,"normal")
	r.distance=r.length-0.1
	r.x=r.corridor(r.distance).x+12
	var old_x:=r.x
	r.step({},1.0/60,rng)
	check(r.sector==2 and r.score==450 and absf(r.x-old_x)<1,"AC-G01-04 distance complete")
	var s:=Session.new()
	r=River.new()
	s.configure(r,42,"normal")
	s.start()
	s.pause()
	s.advance(5)
	check(r.energy==100 and r.distance==0,"AC-G01-04 pause")
	var a:=Rally.new()
	a.create(rng,"normal")
	a.step({"up":true},1.0/60,rng)
	check(a.speed==0,"M3-006 countdown")
	a.countdown=0
	a.elapsed=90-1.0/60
	a.passes=a.goal-1
	a.speed=50
	a.lateral=0
	a.spawn_cd=100
	a.rivals=[{"id":1,"lane":0,"z":0.1,"speed":10.0,"counted":false,"hit":false}]
	check(a.step({},1.0/60,rng).is_empty() and a.day==2 and a.score==850,"AC-G02-01 last tick success")
	a.create(rng,"normal")
	a.countdown=0
	a.elapsed=90-1.0/60
	check(not a.step({},1.0/60,rng).is_empty(),"AC-G02-01 goal failure")
	a.create(rng,"normal")
	a.countdown=0
	a.spawn_cd=100
	a.speed=50
	a.lateral=0
	a.rivals=[{"id":1,"lane":1,"z":0.1,"speed":10.0,"counted":false,"hit":false}]
	a.step({},1.0/60,rng)
	check(a.passes==0 and a.integrity==4,"AC-G02-02 collision no pass")
	var before:=a.steering()
	a.ice=true
	check(is_equal_approx(a.steering(),before*0.6),"AC-G02-03 ice")
	# Test 1000 seed lane-generation constraints and actual representative days.
	for seed in range(1000):
		rng.seed=seed
		a.create(rng,["easy","normal","hard"][seed%3])
		a.day=12
		a.begin_day(rng)
		for i in range(20):
			for car: Dictionary in a.rivals:
				car.z-=20
			a.spawn(rng)
		check(a.rivals.size()==16,"M3R-002 actual cap")
		check(a.group_id==8,"M3R-002 multiple groups")
		check(a.rivals.size()<=16,"AC-G02-03 cap")
	var agents: int=0
	var naive_failures: int=0
	for seed in range(12):
		rng.seed=seed
		a.create(rng,["easy","normal","hard"][seed%3])
		a.day=12
		a.begin_day(rng)
		a.lateral=a.lanes[a.safe_lane]
		var initial:=a.day
		var required:=ceili(a.goal*1.25)
		var max_pass: int=0
		for tick in range(5700):
			var target:=agent_lane(a)
			var result:=a.step({"up":true,"left":a.lateral>target+0.015,"right":a.lateral<target-0.015},1.0/60,rng)
			max_pass=maxi(max_pass,a.passes)
			if not result.is_empty() or a.day!=initial:
				break
		if a.day>initial and max_pass>=required:
			agents+=1
		print("RALLY AGENT seed=",seed," passes=",max_pass," required=",required," advanced=",a.day>initial)
		rng.seed=seed
		a.create(rng,["easy","normal","hard"][seed%3])
		a.day=12
		a.begin_day(rng)
		a.lateral=a.lanes[a.safe_lane]
		for tick in range(5700):
			var result:=a.step({"up":true},1.0/60,rng)
			if not result.is_empty() or a.day>12:
				if a.day==12:
					naive_failures+=1
				break
	print("RALLY AGENT SUMMARY ",agents,"/12")
	print("RALLY NAIVE failures=",naive_failures,"/12")
	check(naive_failures==12,"M3-001 naive agent must fail")
	# Empirical proof of completion on representative days; margin is reported separately.
	check(agents==12,"AC-G02-03 representative agent")
	for script: GDScript in [River,Rally]:
		var hash:=replay(script,60)
		check(hash==replay(script,30) and hash==replay(script,120),"M3 replay "+script.resource_path)
		print("REPLAY ",script.resource_path," ",hash)
	var app: Control=(load("res://app/main.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await process_frame
	for id: String in ["G01","G02","G03"]:
		app.call("_start_game",id)
		await process_frame
		check(app.page=="game" and app.active_game.game_id==id,"M3 FREE "+id)
		app.call("_catalog")
		await process_frame
	app.queue_free()
	await process_frame
	print("M3 failures: ",failures)
	quit(1 if failures else 0)
