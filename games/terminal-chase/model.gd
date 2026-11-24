extends RefCounted
const W: float=640
const H: float=248
const R: float=10
const COLS: Array[float]=[56,232,408,584]
const ROWS: Array[float]=[35,124,213]
const ZONES: Array[int]=[1,6,10]
const EXITS: Array[int]=[0,7,11]
var difficulty: int=1
var score: int=0
var lives: int=3
var round: int=1
var time: float=0
var remaining: float=65
var player:=Vector2(56,124)
var robot:=Vector2(584,213)
var robot_from: int=11
var robot_to: int=10
var robot_speed: float=180
var activated: Array[bool]=[false,false,false]
var active_count: int=0
var progress: float=0
var progress_zone: int=-1
var dash_left: float=0
var dash_cd: float=0
var stun: float=0
var immune: float=0
var contact_hint: float=0
var exit_id: int=0
var door_a: int=1
var door_b: int=2
var door_closed: bool=false
var door_warning: bool=false
var conveyor_warning: bool=false
var exit_revealed: bool=false
var last_axis:=Vector2.RIGHT
var walls: Array[Rect2]=[]
var maintenance: Array[Rect2]=[]
var drones: Array[Dictionary]=[]
func node(id: int) -> Vector2:
	return Vector2(COLS[id%4],ROWS[int(id/4.0)])
func create(rng: RandomNumberGenerator,level: String) -> void:
	difficulty=["easy","normal","hard"].find(level)
	score=0
	lives=[4,3,2][difficulty]
	round=1
	setup(rng)
func setup(rng: RandomNumberGenerator) -> void:
	time=0
	remaining=maxf(float([40,35,30][difficulty]),float([75,65,55][difficulty])-2*(round-1))
	player=node(4)
	robot_from=11
	robot_to=10
	robot=node(robot_from)
	robot_speed=minf(0.37,float([0.23,0.28,0.32][difficulty])+0.012*(round-1))*W
	activated=[false,false,false]
	active_count=0
	progress=0
	progress_zone=-1
	dash_left=0
	dash_cd=0
	stun=0
	immune=0
	contact_hint=0
	exit_id=EXITS[rng.randi_range(0,2)]
	door_a=1 if rng.randf()<0.5 else 9
	door_b=door_a+1
	door_closed=false
	door_warning=false
	conveyor_warning=false
	exit_revealed=false
	last_axis=Vector2.RIGHT
	walls.clear()
	for y in range(2):
		for x in range(3):
			walls.append(Rect2(Vector2(COLS[x]+25,ROWS[y]+25),Vector2(COLS[x+1]-COLS[x]-50,ROWS[y+1]-ROWS[y]-50)))
	maintenance=[Rect2(270,103,92,42)]
	drones.clear()
	for i in range(mini(4,1+int(round/2.0))):
		drones.append({"pos":node(8+i),"phase":rng.randf_range(0,TAU),"row":[2,1,0,2][i]})
func neighbors(id: int,avoid_door: bool=true) -> Array[int]:
	var result: Array[int]=[]
	for n: int in [id-1,id+1,id-4,id+4]:
		if n<0 or n>=12 or (absi(n-id)==1 and int(n/4.0)!=int(id/4.0)):
			continue
		if avoid_door and door_closed and ((id==door_a and n==door_b) or (id==door_b and n==door_a)):
			continue
		result.append(n)
	return result
func path(start: int,target: int) -> Array[int]:
	var queue: Array[int]=[start]
	var previous: Dictionary={start:-1}
	var index: int=0
	while index<queue.size():
		var current:=queue[index]
		index+=1
		if current==target:
			var result: Array[int]=[]
			while current!=-1:
				result.push_front(current)
				current=previous[current]
			return result
		for n: int in neighbors(current):
			if not previous.has(n):
				previous[n]=current
				queue.append(n)
	return []
func nearest(point: Vector2) -> int:
	var best: int=0
	for i in range(1,12):
		if point.distance_squared_to(node(i))<point.distance_squared_to(node(best)):
			best=i
	return best
func door_rect() -> Rect2:
	var mid: Vector2=(node(door_a)+node(door_b))/2
	return Rect2(mid-Vector2(5,25),Vector2(10,50))
func blocked(point: Vector2) -> bool:
	for wall: Rect2 in walls:
		if wall.grow(R).has_point(point):
			return true
	return door_closed and door_rect().grow(R).has_point(point)
func clear_contact(a: Vector2,b: Vector2) -> bool:
	for i in range(1,9):
		if blocked(a.lerp(b,float(i)/8)):
			return false
	return true
func update_door() -> void:
	var cycle:=fposmod(time,9.0)
	door_warning=cycle>=4 and cycle<5
	var on_edge: bool=(robot_from==door_a and robot_to==door_b) or (robot_from==door_b and robot_to==door_a)
	door_closed=cycle>=5 and cycle<7 and not on_edge and not door_rect().grow(20).has_point(player)
func choose_robot(rng: RandomNumberGenerator,previous: int) -> int:
	if remaining<=10:
		var route:=path(robot_from,exit_id)
		if route.size()>1:
			return route[1]
	var choices:=neighbors(robot_from)
	if choices.size()>1:
		choices.erase(previous)
	var preferred: Array[int]=[]
	for n: int in choices:
		var zone:=ZONES.find(n)
		if zone<0 or not activated[zone]:
			preferred.append(n)
	if not preferred.is_empty():
		choices=preferred
	if choices.is_empty():
		return previous
	# Evade the player instead of blindly moving; occasional seeded choice prevents a fixed loop.
	if active_count>=2 and rng.randf()<minf(0.82,0.50+0.035*(round-1)):
		var best: int=choices[0]
		for candidate: int in choices:
			if node(candidate).distance_squared_to(player)>node(best).distance_squared_to(player):
				best=candidate
		return best
	return choices[rng.randi_range(0,choices.size()-1)]
func lose(rng: RandomNumberGenerator,reason: String) -> Dictionary:
	lives-=1
	if lives<=0:
		return {"score":score,"progress":round,"reason":reason}
	setup(rng)
	return {}
func step(input: Dictionary,dt: float,rng: RandomNumberGenerator) -> Dictionary:
	time+=dt
	remaining=maxf(0,remaining-dt)
	dash_cd=maxf(0,dash_cd-dt)
	dash_left=maxf(0,dash_left-dt)
	stun=maxf(0,stun-dt)
	immune=maxf(0,immune-dt)
	contact_hint=maxf(0,contact_hint-dt)
	update_door()
	conveyor_warning=fposmod(time,4.0)>=3.0
	exit_revealed=exit_revealed or remaining<=15
	var axis:=Vector2(float(int(input.get("right",false))-int(input.get("left",false))),float(int(input.get("down",false))-int(input.get("up",false))))
	var analog: Dictionary=input.get("analog",{})
	if analog.has("stick"):
		var delta: Vector2=analog.stick.delta
		axis=Vector2.ZERO if delta.length()<8 else delta.normalized()*clampf((delta.length()-8)/30,0,1)
	axis=axis.limit_length(1)
	if axis.length()>0.05:
		last_axis=axis.normalized()
	if input.get("pressed",{}).has("secondary") and dash_cd<=0 and stun<=0:
		dash_cd=5
		dash_left=0.25
	var speed:=0.43*W*(1.75 if dash_left>0 else 1.0)
	for area: Rect2 in maintenance:
		if area.has_point(player):
			speed*=0.65
	var move:=axis*speed*dt if stun<=0 else Vector2.ZERO
	if dash_left>0 and stun<=0:
		move=last_axis*speed*dt
	# Conveyor on central horizontal segment, alternates direction with warning.
	if Rect2(65,103,130,42).has_point(player):
		move.x+=float(1 if fposmod(time,8)<4 else -1)*(0.12*W)*dt
	var next:=player+Vector2(move.x,0)
	if not blocked(next):
		player.x=clampf(next.x,R,W-R)
	next=player+Vector2(0,move.y)
	if not blocked(next):
		player.y=clampf(next.y,R,H-R)
	var zone: int=-1
	for i in range(3):
		if not activated[i] and active_count<2 and player.distance_to(node(ZONES[i]))<23:
			zone=i
	if zone>=0 and stun<=0 and (input.get("action",false) or input.get("fire",false)):
		if progress_zone!=zone:
			progress=0
			progress_zone=zone
		progress+=dt
		if progress>=0.6-0.000001:
			activated[zone]=true
			active_count+=1
			progress=0
			progress_zone=-1
	else:
		progress=0
		progress_zone=-1
	robot=robot.move_toward(node(robot_to),robot_speed*dt)
	if robot.distance_to(node(robot_to))<0.001:
		var previous:=robot_from
		robot_from=robot_to
		if remaining<=10 and robot_from==exit_id:
			return lose(rng,"escape")
		robot_to=choose_robot(rng,previous)
	for d: Dictionary in drones:
		var lane: float=ROWS[d.row]
		d.pos=Vector2(320+cos(time*0.8+d.phase)*225,lane)
		if immune<=0 and player.distance_to(d.pos)<20:
			remaining=maxf(0,remaining-5)
			stun=0.45
			immune=1
	if remaining<=0:
		return lose(rng,"timeout")
	if player.distance_to(robot)<R+13 and clear_contact(player,robot):
		if active_count>=2:
			score+=450+int(floor(remaining*12))
			round+=1
			setup(rng)
		else:
			contact_hint=1
	return {}
