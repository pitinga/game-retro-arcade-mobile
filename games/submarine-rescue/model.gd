extends RefCounted
const W: float=640.0
const H: float=248.0
const R: float=11.0
var pos:=Vector2(W/2,0.07*H)
var velocity:=Vector2.ZERO
var direction: int=1
var oxygen: float=100
var lives: int=3
var score: int=0
var wave: int=1
var difficulty: int=1
var cargo: int=0
var delivered: int=0
var cooldown: float=0
var immune: float=0
var time: float=0
var spawn_timer: float=0
var wave_wait: float=0
var next_id: int=0
var capsules: Array[Dictionary]=[]
var enemies: Array[Dictionary]=[]
var shots: Array[Dictionary]=[]
func capacity() -> int:
	return [4,4,3][difficulty]
func goal() -> int:
	return [4,6,8][difficulty]
func create(rng: RandomNumberGenerator,level: String) -> void:
	difficulty=["easy","normal","hard"].find(level)
	score=0
	wave=1
	lives=[4,3,2][difficulty]
	delivered=0
	time=0
	next_id=0
	wave_wait=0
	reset_vehicle()
	setup_wave(rng)
func reset_vehicle() -> void:
	pos=Vector2(W/2,0.07*H)
	velocity=Vector2.ZERO
	oxygen=100
	cargo=0
	immune=1.2
	cooldown=0
	direction=1
	shots.clear()
func add_capsule(rng: RandomNumberGenerator) -> void:
	next_id+=1
	# Reserve a shallow rescue route; other capsules offer deeper risk.
	var shallow: bool=true
	for c: Dictionary in capsules:
		if c.pos.y<=0.40*H:
			shallow=false
	var p:=Vector2(rng.randf_range(0.16,0.84)*W,rng.randf_range(0.30,0.38)*H if shallow else rng.randf_range(0.48,0.86)*H)
	for c: Dictionary in capsules:
		if Vector2(c.pos).distance_to(p)<28:
			return
	capsules.append({"id":next_id,"pos":p})
func setup_wave(rng: RandomNumberGenerator) -> void:
	capsules.clear()
	enemies.clear()
	shots.clear()
	for i in range(6):
		add_capsule(rng)
	for i in range(mini(8,3+int(wave/2.0))):
		var p:=Vector2(rng.randf_range(0.08,0.92)*W,rng.randf_range(0.56,0.88)*H)
		if absf(p.x-pos.x)<0.20*W:
			p.x=0.10*W if pos.x>W/2 else 0.90*W
		enemies.append({"pos":p,"vx":rng.randf_range(35,75)*(-1 if i%2==0 else 1),"kind":i%2})
	spawn_timer=2
func lose() -> Dictionary:
	lives-=1
	if lives<=0:
		cargo=0
		return {"score":score,"progress":wave,"reason":"lost"}
	reset_vehicle()
	return {}
func step(input: Dictionary,dt: float,rng: RandomNumberGenerator) -> Dictionary:
	time+=dt
	immune=maxf(0,immune-dt)
	cooldown=maxf(0,cooldown-dt)
	if wave_wait>0:
		wave_wait=maxf(0,wave_wait-dt)
		if wave_wait==0:
			setup_wave(rng)
		return {}
	var axis:=Vector2(float(int(input.get("right",false))-int(input.get("left",false))),float(int(input.get("down",false))-int(input.get("up",false))))
	var analog: Dictionary=input.get("analog",{})
	if analog.has("stick"):
		var delta: Vector2=analog.stick.delta
		axis=Vector2.ZERO if delta.length()<=8 else delta.normalized()*clampf((delta.length()-8)/30,0,1)
	axis=axis.limit_length(1.0)
	velocity=axis*Vector2(0.48*W,0.65*H)
	if absf(axis.x)>0.05:
		direction=1 if axis.x>0 else -1
	if wave>=3 and pos.y>0.2*H:
		velocity.x+=sin(time*0.6)*0.12*W
	pos=(pos+velocity*dt).clamp(Vector2(R,0.04*H),Vector2(W-R,0.95*H))
	var surface:=pos.y<=0.10*H
	if surface and absf(velocity.x)<=0.05*W and absf(velocity.y)<=0.05*H:
		oxygen=minf(100,oxygen+35*dt)
		if cargo>0:
			score+=200*cargo+(150 if cargo==capacity() else 0)
			delivered+=cargo
			cargo=0
			if delivered>=goal():
				delivered-=goal()
				wave+=1
				wave_wait=1
				enemies.clear()
				shots.clear()
				return {}
	elif not surface:
		oxygen=maxf(0,oxygen-float([5,6,7][difficulty])*dt)
	if oxygen<=0:
		return lose()
	if input.get("fire",false) and cooldown<=0 and shots.size()<12:
		shots.append({"pos":pos,"vx":direction*480.0})
		cooldown=0.22
	for i in range(capsules.size()-1,-1,-1):
		if cargo<capacity() and pos.distance_to(capsules[i].pos)<R+9:
			capsules.remove_at(i)
			cargo+=1
	spawn_timer-=dt
	if spawn_timer<=0 and capsules.size()<6:
		add_capsule(rng)
		spawn_timer=2
	for e: Dictionary in enemies:
		e.pos.x+=float(e.vx)*dt
		if e.pos.x<R or e.pos.x>W-R:
			e.vx=-float(e.vx)
			e.pos.x=clampf(e.pos.x,R,W-R)
		if immune<=0 and pos.distance_to(e.pos)<R+12:
			return lose()
	for i in range(shots.size()-1,-1,-1):
		var s: Dictionary=shots[i]
		var start: Vector2=s.pos
		var delta:=Vector2(float(s.vx)*dt,0)
		var hit: int=-1
		var first: float=2
		for j in enemies.size():
			var t:=preload("res://core/geometry.gd").segment_circle(start,delta,enemies[j].pos,12)
			if t>=0 and t<first:
				first=t
				hit=j
		if hit>=0:
			score+=75 if enemies[hit].kind==0 else 50
			enemies.remove_at(hit)
			shots.remove_at(i)
		else:
			s.pos=start+delta
			if s.pos.x<0 or s.pos.x>W:
				shots.remove_at(i)
	return {}
