extends RefCounted
const Geo=preload("res://core/geometry.gd")
const W: float=640.0
const H: float=312.0
var difficulty: int=1
var score: int=0
var wave: int=1
var habitats: Array[bool]=[true,true,true,true,true]
var launchers: Array[bool]=[true,true]
var ammo: Array[int]=[10,10]
var positions: Array[Vector2]=[Vector2(48,H-15),Vector2(590,H-26),Vector2(130,H-15),Vector2(220,H-15),Vector2(320,H-15),Vector2(420,H-15),Vector2(510,H-15)]
var threats: Array[Dictionary]=[]
var shots: Array[Dictionary]=[]
var bubbles: Array[Dictionary]=[]
var remaining: int=0
var spawned: int=0
var spawn_cd: float=0
var cooldown: float=0
var repair_threshold: int=5000
var wave_wait: float=-1
var cursor:=Vector2(W/2,H*0.4)
func create(_rng: RandomNumberGenerator,level: String) -> void:
	difficulty=["easy","normal","hard"].find(level)
	habitats=[true,true,true,true,true]
	launchers=[true,true]
	score=0
	wave=1
	repair_threshold=5000
	begin_wave()
func begin_wave() -> void:
	remaining=mini(45,int([9,12,15][difficulty])+2*(wave-1))
	spawned=0
	spawn_cd=1
	cooldown=0
	wave_wait=-1
	threats.clear()
	shots.clear()
	bubbles.clear()
	for i in range(2):
		ammo[i]=int([12,10,8][difficulty]) if launchers[i] else 0
func target_alive(target: int) -> bool:
	return launchers[target] if target<2 else habitats[target-2]
func spawn_threat(rng: RandomNumberGenerator) -> void:
	var targets: Array[int]=[]
	for i in range(7):
		if target_alive(i):
			targets.append(i)
	if targets.is_empty():
		return
	var target: int=targets[rng.randi_range(0,targets.size()-1)]
	var origin:=Vector2(rng.randf_range(15,W-15),0)
	var speed:=minf(0.33,float([0.10,0.14,0.18][difficulty])+0.008*float(wave-1))*H
	threats.append({"pos":origin,"start":origin,"target":target,"speed":speed,"fragment":wave>=3 and spawned%5==4,"child":false})
	remaining-=1
	spawned+=1
func fire(target: Vector2) -> bool:
	if cooldown>0 or wave_wait>=0:
		return false
	target=target.clamp(Vector2.ZERO,Vector2(W,H-34))
	var chosen: int=-1
	var distance: float=INF
	for i in range(2):
		if launchers[i] and ammo[i]>0 and positions[i].distance_squared_to(target)<distance:
			chosen=i
			distance=positions[i].distance_squared_to(target)
	if chosen<0:
		return false
	ammo[chosen]-=1
	cooldown=0.15
	shots.append({"pos":positions[chosen],"target":target})
	return true
func bubble_radius(age: float) -> float:
	if age<0.42:
		return maxf(0,age/0.42)*0.12*H
	if age<=0.70:
		return 0.12*H
	return maxf(0,1-(age-0.70)/0.35)*0.12*H
func lost() -> bool:
	return not habitats.has(true) or not launchers.has(true)
func complete_wave() -> void:
	score+=habitats.count(true)*100+(ammo[0]+ammo[1])*20
	if wave%3==0 and launchers.has(false):
		launchers[launchers.find(false)]=true
	while score>=repair_threshold:
		if habitats.has(false):
			habitats[habitats.find(false)]=true
		repair_threshold+=5000
	wave_wait=1.5
func step(input: Dictionary,dt: float,rng: RandomNumberGenerator) -> Dictionary:
	if lost():
		return {"score":score,"progress":wave,"reason":"lost"}
	if wave_wait>=0:
		wave_wait-=dt
		if wave_wait<=0:
			wave+=1
			begin_wave()
		return {}
	cooldown=maxf(0,cooldown-dt)
	cursor=(cursor+Vector2(float(int(input.get("right",false))-int(input.get("left",false))),float(int(input.get("down",false))-int(input.get("up",false)))).normalized()*250*dt).clamp(Vector2.ZERO,Vector2(W,H-34))
	var pressed: Dictionary=input.get("pressed",{})
	if pressed.has("aim"):
		cursor=(Vector2(pressed.aim)-Vector2(0,48)).clamp(Vector2.ZERO,Vector2(W,H-34))
		fire(cursor)
	elif pressed.has("fire") or pressed.has("action"):
		fire(cursor)
	spawn_cd-=dt
	if remaining>0 and threats.size()<24 and spawn_cd<=0:
		spawn_threat(rng)
		spawn_cd=maxf(0.35,1.2-float(wave-1)*0.045)
	for i in range(shots.size()-1,-1,-1):
		var shot: Dictionary=shots[i]
		shot.pos=Vector2(shot.pos).move_toward(shot.target,1.15*H*dt)
		if Vector2(shot.pos).distance_squared_to(shot.target)<0.00001:
			bubbles.append({"pos":shot.target,"age":0.0})
			shots.remove_at(i)
	for bubble: Dictionary in bubbles:
		bubble.age+=dt
	for i in range(threats.size()-1,-1,-1):
		var t: Dictionary=threats[i]
		var target: Vector2=positions[t.target]
		var previous: Vector2=t.pos
		var next:=previous.move_toward(target,float(t.speed)*dt)
		var intercepted: bool=false
		for bubble: Dictionary in bubbles:
			if Geo.segment_circle(previous,next-previous,bubble.pos,bubble_radius(float(bubble.age)))>=0:
				intercepted=true
				break
		if intercepted:
			score+=40 if t.child else 80
			threats.remove_at(i)
			continue
		t.pos=next
		if next.distance_squared_to(target)<=0.00001:
			if t.target<2:
				launchers[t.target]=false
				ammo[t.target]=0
			else:
				habitats[t.target-2]=false
			threats.remove_at(i)
			if lost():
				return {"score":score,"progress":wave,"reason":"lost"}
			continue
		if t.fragment and next.y>=H*0.48 and threats.size()<24:
			threats.remove_at(i)
			for direction: int in [-1,1]:
				var alternate:=clampi(int(t.target)+direction,2,6)
				threats.append({"pos":next+Vector2(direction*4,0),"start":next,"target":alternate,"speed":t.speed,"fragment":false,"child":true})
	for i in range(bubbles.size()-1,-1,-1):
		if bubbles[i].age>=1.05:
			bubbles.remove_at(i)
	if remaining==0 and threats.is_empty() and shots.is_empty() and bubbles.is_empty():
		complete_wave()
	return {}
