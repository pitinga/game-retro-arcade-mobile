extends SceneTree
const Brick=preload("res://games/brick-breaker/model.gd")
const Orbit=preload("res://games/asteroid-shooter/model.gd")
const Shield=preload("res://games/missile-defense/model.gd")
const Session=preload("res://core/session.gd")
const Geo=preload("res://core/geometry.gd")
const View=preload("res://app/game_view.gd")
var failures: int=0
var rng:=RandomNumberGenerator.new()
func check(ok: bool,label: String) -> void:
	if not ok:
		failures+=1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	rng.seed=17
	var b:=Brick.new()
	b.create(rng,"normal")
	check(b.lives==3 and is_equal_approx(b.paddle_width(),72),"AC-G03-04 normal")
	var distinct: Dictionary={}
	for phase in range(1,31):
		b.phase=phase
		b.build_level(rng)
		var key: String=""
		for block: Dictionary in b.blocks:
			var rect: Rect2=block.rect
			check(rect.position.x>=0 and rect.end.x<=360 and rect.end.y<200,"AC-G03-02 bounds")
			key+=str(block.id)+";"
		distinct[key]=true
	check(distinct.size()==10,"M2-003 ten topologies, three tiers")
	for seed in range(1000):
		rng.seed=seed
		b.phase=31
		b.build_level(rng)
		check(not b.blocks.is_empty() and b.blocks.size()<=54,"AC-G03-04 endless seed "+str(seed))
	b.create(rng,"normal")
	b.blocks=[{"id":1,"rect":Rect2(160,120,34,20),"hp":3,"initial":3}]
	b.hit_block(0,rng)
	b.hit_block(0,rng)
	check(b.blocks.size()==1 and b.blocks[0].hp==1 and b.score==0,"AC-G03-02 HP")
	b.hit_block(0,rng)
	check(b.blocks.is_empty() and b.score==150,"AC-G03-02 score")
	var collision:=Geo.sweep_circle_rect(Vector2(180,170),Vector2(0,-90),5,Rect2(160,120,34,20))
	check(not collision.is_empty() and is_equal_approx(collision.time,25.0/90.0),"AC-G03-01 sweep")
	check(Geo.sweep_circle_rect(Vector2(120,100),Vector2(20,0),5,Rect2(160,120,34,20)).is_empty(),"AC-G03-01 miss")
	b.create(rng,"hard")
	b.serving=false
	b.ball=Vector2(12,Brick.H+Brick.R-1)
	b.velocity=Vector2(0,Brick.H)
	b.lives=1
	check(not b.step({},1.0/60,rng).is_empty() and b.lives==0,"AC-G03-03 terminal")
	b.create(rng,"normal")
	var old:=b.paddle
	b.step({"analog":{"paddle":{"id":4,"delta":Vector2(200,0)}}},1.0/60,rng)
	check(b.paddle>old and b.paddle-old<=12.001,"AC-G03-04 no jump")
	var orbit:=Orbit.new()
	orbit.create(rng,"normal")
	orbit.rocks.clear()
	orbit.add_rock(Vector2(200,100),Vector2.ZERO,2)
	while not orbit.rocks.is_empty():
		orbit.destroy(0,rng)
	check(orbit.score==730,"AC-G09-02 fragmentation")
	check(orbit.offset(Vector2(639,100),Vector2(1,100))==Vector2(2,0),"AC-G09-01 torus")
	orbit.create(rng,"hard")
	for wave in range(1,101):
		orbit.wave=wave
		orbit.spawn_wave(rng)
		check(orbit.rocks.size()<=10,"AC-G09-04 initial cap")
		while not orbit.rocks.is_empty():
			orbit.destroy(0,rng)
			check(orbit.rocks.size()<=48,"AC-G09-04 fragments cap")
		orbit.step({},1.0/60,rng)
		check(orbit.wave_wait>0,"AC-G09-03 wave delay")
	orbit.create(rng,"normal")
	orbit.immune=0
	orbit.rocks.clear()
	orbit.add_rock(orbit.ship,Vector2.ZERO,0)
	var old_lives:=orbit.lives
	orbit.step({},1.0/60,rng)
	check(orbit.lives==old_lives-1 and orbit.respawn>=0,"AC-G09-03 one loss")
	orbit.step({},1.0/60,rng)
	check(orbit.lives==old_lives-1,"AC-G09-03 no repeat")
	var shield:=Shield.new()
	shield.create(rng,"normal")
	check(shield.fire(Vector2(40,180)) and shield.ammo==[9,10],"AC-G10-01 launcher A")
	check(not shield.fire(Vector2(40,180)),"AC-G10-01 cooldown")
	shield.cooldown=0
	shield.ammo[0]=0
	check(shield.fire(Vector2(40,180)) and shield.ammo[1]==9,"AC-G10-01 fallback")
	shield.ammo=[0,0]
	shield.cooldown=0
	check(not shield.fire(Vector2(40,180)),"AC-G10-01 zero")
	check(is_equal_approx(shield.bubble_radius(0.42),0.12*Shield.H) and is_zero_approx(shield.bubble_radius(1.05)),"AC-G10-02 radius")
	shield.create(rng,"normal")
	shield.remaining=0
	shield.threats=[{"pos":Vector2(220,100),"start":Vector2(220,0),"target":3,"speed":100.0,"fragment":false,"child":false}]
	shield.bubbles=[{"pos":Vector2(220,100),"age":0.42},{"pos":Vector2(220,100),"age":0.42}]
	shield.step({},1.0/60,rng)
	check(shield.score==80 and shield.threats.is_empty() and shield.wave_wait<0,"AC-G10-02 once and pending")
	shield.bubbles.clear()
	shield.step({},1.0/60,rng)
	check(shield.wave_wait>0 and shield.score==980,"AC-G10-03 wave once")
	shield.create(rng,"normal")
	shield.launchers=[false,false]
	check(not shield.step({},1.0/60,rng).is_empty(),"AC-G10-03 terminal")
	for seed in range(1000):
		rng.seed=seed
		shield.create(rng,"hard")
		shield.wave=10
		shield.begin_wave()
		while shield.remaining>0 and shield.threats.size()<24:
			shield.spawn_threat(rng)
		check(shield.threats.size()<=24 and shield.remaining>=0,"AC-G10-04 spawn cap")
		for threat: Dictionary in shield.threats:
			check(threat.target>=0 and threat.target<7 and threat.speed<=0.33*Shield.H,"AC-G10-04 target speed")
	for id: String in ["G03","G09","G10"]:
		var view:=View.new()
		view.configure(id,"normal","pt",{},42)
		root.add_child(view)
		view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await process_frame
		check(view.host.session.state==Session.State.PAUSED,"M2 intro "+id)
		check(view.pause_button.size.y/float(view.fitted.scale)>=47.99,"M2-001 pause size "+id) if view.fitted.scale>0 else check(false,"M2-001 layout "+id)
		view._resume()
		view.pause_game()
		check(view.host.session.state==Session.State.PAUSED,"M2 pause "+id)
		view.queue_free()
		await process_frame
	var app: Control=(load("res://app/main.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await process_frame
	app.call("_start_game","G09")
	check(app.page=="details","M2 PRO access blocked")
	app.call("_start_game","G03")
	await process_frame
	check(app.page=="game" and app.back_action()=="pause","M2 FREE playable")
	app.queue_free()
	await process_frame
	print("M2 failures: ",failures)
	quit(1 if failures else 0)
