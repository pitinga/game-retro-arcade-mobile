extends RefCounted
const Geo=preload("res://core/geometry.gd")
const W: float=640.0
const H: float=248.0
const SIZE:=Vector2(W,H)
var difficulty: int=1
var ship:=SIZE/2
var velocity:=Vector2.ZERO
var angle: float=-PI/2
var score: int=0
var lives: int=3
var wave: int=1
var rocks: Array[Dictionary]=[]
var shots: Array[Dictionary]=[]
var next_id: int=0
var fire_cd: float=0
var dash_cd: float=0
var immune: float=0
var respawn: float=-1
var wave_wait: float=-1
func create(rng: RandomNumberGenerator,level: String) -> void:
	difficulty=["easy","normal","hard"].find(level)
	lives=[4,3,2][difficulty]
	ship=SIZE/2
	velocity=Vector2.ZERO
	angle=-PI/2
	score=0
	wave=1
	next_id=0
	fire_cd=0
	dash_cd=0
	respawn=-1
	spawn_wave(rng)
func wrap_position(point: Vector2) -> Vector2:
	return Vector2(fposmod(point.x,W),fposmod(point.y,H))
func offset(from: Vector2,to: Vector2) -> Vector2:
	var d:=to-from
	return Vector2(fposmod(d.x+W/2,W)-W/2,fposmod(d.y+H/2,H)-H/2)
func radius(size: int) -> float:
	return [9.0,18.0,30.0,12.0][size]
func add_rock(pos: Vector2,vel: Vector2,size: int) -> void:
	next_id+=1
	rocks.append({"id":next_id,"pos":wrap_position(pos),"vel":vel,"size":size})
func spawn_wave(rng: RandomNumberGenerator) -> void:
	rocks.clear()
	shots.clear()
	var count:=mini(9,int([3,4,5][difficulty])+wave-1)
	for index in count:
		var pos:=wrap_position(ship+Vector2.from_angle(TAU*float(index)/float(count))*100)
		var speed:=rng.randf_range(28,75)*float([0.8,1,1.2][difficulty])
		add_rock(pos,Vector2.from_angle(rng.randf_range(0,TAU))*speed,2)
	if wave>=3:
		add_rock(wrap_position(ship+Vector2(W/2,0)),Vector2.ZERO,3)
	immune=1.2
	wave_wait=-1
func destroy(index: int,rng: RandomNumberGenerator) -> void:
	var rock: Dictionary=rocks[index]
	rocks.remove_at(index)
	var size: int=rock.size
	score+=int([140,70,30,250][size])
	if size in [1,2]:
		var direction:=Vector2.from_angle(rng.randf_range(0,TAU))
		var pos: Vector2=rock.pos
		var vel: Vector2=rock.vel
		var distance:=radius(size-1)+2
		for sign_value: int in [-1,1]:
			add_rock(pos+direction*distance*sign_value,(vel+direction*24*sign_value).limit_length(100),size-1)
func safe_at(point: Vector2) -> bool:
	for rock: Dictionary in rocks:
		if Geo.segment_circle(offset(point,rock.pos),Vector2(rock.vel)*1.2,Vector2.ZERO,radius(rock.size)+15)>=0:
			return false
	return true
func try_respawn() -> bool:
	for y: float in [0.5,0.25,0.75]:
		for x: float in [0.5,0.25,0.75,0.1,0.9]:
			var point:=Vector2(W*x,H*y)
			if safe_at(point):
				ship=point
				velocity=Vector2.ZERO
				immune=1.2
				respawn=-1
				return true
	return false
func step(input: Dictionary,dt: float,rng: RandomNumberGenerator) -> Dictionary:
	fire_cd=maxf(0,fire_cd-dt)
	dash_cd=maxf(0,dash_cd-dt)
	immune=maxf(0,immune-dt)
	if wave_wait>=0:
		wave_wait-=dt
		if wave_wait<=0:
			wave+=1
			spawn_wave(rng)
		return {}
	if respawn>=0:
		respawn+=dt
		if not try_respawn() and respawn>=2:
			ship=SIZE/2
			for i in range(rocks.size()-1,-1,-1):
				if offset(ship,rocks[i].pos).length()<85:
					rocks.remove_at(i)
			velocity=Vector2.ZERO
			immune=1.2
			respawn=-1
	else:
		angle=fposmod(angle+float(int(input.get("right",false))-int(input.get("left",false)))*3.8*dt,TAU)
		var forward:=Vector2.from_angle(angle)
		if input.get("up",false):
			velocity+=forward*180*dt
		var pressed: Dictionary=input.get("pressed",{})
		if pressed.has("secondary") and dash_cd<=0:
			velocity+=forward*120
			immune=maxf(immune,0.3)
			dash_cd=float([8,10,12][difficulty])
		velocity=(velocity*exp(-0.12*dt)).limit_length(225)
		if (input.get("fire",false) or input.get("action",false)) and fire_cd<=0 and shots.size()<12:
			shots.append({"pos":wrap_position(ship+forward*12),"vel":forward*380+velocity,"ttl":1.0})
			fire_cd=0.18
		for rock: Dictionary in rocks:
			if rock.size==3:
				rock.vel=offset(rock.pos,ship).normalized()*65
		if immune<=0:
			for rock: Dictionary in rocks:
				if Geo.segment_circle(offset(ship,rock.pos),(Vector2(rock.vel)-velocity)*dt,Vector2.ZERO,radius(rock.size)+9)>=0:
					lives-=1
					if lives<=0:
						return {"score":score,"progress":wave,"reason":"lost"}
					respawn=0
					break
		ship=wrap_position(ship+velocity*dt)
	for i in range(shots.size()-1,-1,-1):
		var shot: Dictionary=shots[i]
		var best: float=2
		var target: int=-1
		for j in rocks.size():
			var rock: Dictionary=rocks[j]
			var time:=Geo.segment_circle(offset(rock.pos,shot.pos),(Vector2(shot.vel)-Vector2(rock.vel))*dt,Vector2.ZERO,radius(rock.size))
			if time>=0 and time<best:
				best=time
				target=j
		if target>=0:
			destroy(target,rng)
			shots.remove_at(i)
		else:
			shot.pos=wrap_position(Vector2(shot.pos)+Vector2(shot.vel)*dt)
			shot.ttl-=dt
			if shot.ttl<=0:
				shots.remove_at(i)
	for rock: Dictionary in rocks:
		rock.pos=wrap_position(Vector2(rock.pos)+Vector2(rock.vel)*dt)
	if rocks.is_empty() and respawn<0:
		score+=200
		wave_wait=1.5
	return {}
