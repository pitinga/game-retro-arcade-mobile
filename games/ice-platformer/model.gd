extends RefCounted
const W: float=640.0
const H: float=248.0
const R: float=10.0
const JUMP: float=0.34
var difficulty: int=1
var score: int=0
var lives: int=3
var phase: int=1
var energy: float=100
var time: float=0
var pos:=Vector2(110,124)
var stations: Array[Vector2]=[Vector2(110,124),Vector2(320,124),Vector2(530,124)]
var repaired: Array[bool]=[false,false,false]
var checkpoint: int=0
var platforms: Array[Dictionary]=[]
var drones: Array[Dictionary]=[]
var direction:=Vector2.UP
var support: int=-1
var jump_left: float=0
var jump_from:=Vector2.ZERO
var jump_to:=Vector2.ZERO
var buffer: float=0
var repair_time: float=0
var repair_index: int=-1
var phase_angle: float=0
func create(rng: RandomNumberGenerator,level: String) -> void:
	difficulty=["easy","normal","hard"].find(level)
	score=0
	lives=[4,3,2][difficulty]
	phase=1
	setup(rng)
func setup(rng: RandomNumberGenerator) -> void:
	time=0
	phase_angle=rng.randf_range(0,TAU)
	repaired=[false,false,false]
	checkpoint=0
	pos=stations[0]
	support=-1
	energy=100
	jump_left=0
	buffer=0
	repair_time=0
	repair_index=-1
	platforms.clear()
	drones.clear()
	# Each station is linked by moving ellipse platforms; no copied maps.
	for station in range(3):
		for index in range(6):
			platforms.append({"station":station,"angle":float(index)*TAU/6+phase_angle,"pos":Vector2.ZERO})
	update_platforms(0)
	if phase>=3:
		for i in range(mini(4,phase-2)):
			drones.append({"pos":Vector2(180+i*90,40),"offset":i*1.6})
func update_platforms(dt: float) -> void:
	var angular:=float([0.12,0.17,0.22][difficulty])*W/75
	for p: Dictionary in platforms:
		p.angle=fposmod(float(p.angle)+angular*dt,TAU)
		p.pos=stations[p.station]+Vector2(cos(p.angle)*83,sin(p.angle)*56)
# Directional jump assistance predicts moving platforms at landing time.
func target_in_direction() -> Vector2:
	var best:=pos+direction*0.20*W
	var best_distance: float=INF
	var angular:=float([0.12,0.17,0.22][difficulty])*W/75
	var candidates: Array[Vector2]=stations.duplicate()
	for platform: Dictionary in platforms:
		var angle:=float(platform.angle)+angular*JUMP
		candidates.append(stations[platform.station]+Vector2(cos(angle)*83,sin(angle)*56))
	for candidate: Vector2 in candidates:
		var delta:=candidate-pos
		var distance:=delta.length()
		if distance<30 or distance>0.20*W or delta.normalized().dot(direction)<0.78:
			continue
		var cost:=absf(0.20*W-distance)+(1-delta.normalized().dot(direction))*100
		if cost<best_distance:
			best_distance=cost
			best=candidate
	return best.clamp(Vector2(R,R),Vector2(W-R,H-R))
func station_at(point: Vector2) -> int:
	for i in range(3):
		if stations[i].distance_to(point)<=31:
			return i
	return -1
func platform_at(point: Vector2) -> int:
	for i in platforms.size():
		if Vector2(platforms[i].pos).distance_to(point)<=26:
			return i
	return -1
func lose() -> Dictionary:
	lives-=1
	score=maxi(0,score-100)
	if lives<=0:
		return {"score":score,"progress":phase,"reason":"lost"}
	pos=stations[checkpoint]
	energy=100
	support=-1
	jump_left=0
	buffer=0
	repair_time=0
	repair_index=-1
	return {}
func step(input: Dictionary,dt: float,rng: RandomNumberGenerator) -> Dictionary:
	time+=dt
	update_platforms(dt)
	var axis:=Vector2(float(int(input.get("right",false))-int(input.get("left",false))),float(int(input.get("down",false))-int(input.get("up",false))))
	if axis.length()>0:
		direction=axis.normalized()
	if input.get("pressed",{}).has("fire"):
		buffer=0.10
	if jump_left<=0:
		if support>=0:
			pos=platforms[support].pos
		if buffer>0:
			jump_from=pos
			jump_to=target_in_direction()
			if phase>=2:
				jump_to.x=clampf(jump_to.x+sin(time)*8,R,W-R)
			jump_left=JUMP
			support=-1
			buffer=0
			repair_time=0
			repair_index=-1
	if jump_left>0:
		jump_left=maxf(0,jump_left-dt)
		pos=jump_from.lerp(jump_to,1-jump_left/JUMP)
		if jump_left<=0:
			var station:=station_at(pos)
			if station>=0:
				pos=stations[station]
				checkpoint=station
			else:
				support=platform_at(pos)
				if support<0:
					return lose()
				pos=platforms[support].pos
	buffer=maxf(0,buffer-dt)
	var station:=station_at(pos) if jump_left<=0 and support<0 else -1
	if station>=0:
		energy=minf(100,energy+15*dt)
		if input.get("action",false) and not repaired[station]:
			if repair_index!=station:
				repair_index=station
				repair_time=0
			repair_time+=dt
			if repair_time>=1.0-0.000001:
				repaired[station]=true
				checkpoint=station
				score+=180
				repair_time=0
				if not repaired.has(false):
					score+=400+int(floor(energy*2))
					phase+=1
					setup(rng)
					return {}
		else:
			repair_time=0
			repair_index=-1
	else:
		energy=maxf(0,energy-float([2.5,3.2,4][difficulty])*dt)
		repair_time=0
		repair_index=-1
	if energy<=0:
		return lose()
	for d: Dictionary in drones:
		d.pos=Vector2(320+cos(time*0.8+d.offset)*245,124+sin(time*1.2+d.offset)*82)
		if jump_left<=0 and station<0 and pos.distance_to(d.pos)<R+12:
			return lose()
	return {}
