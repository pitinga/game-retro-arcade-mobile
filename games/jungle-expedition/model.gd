extends RefCounted
const Data=preload("res://games/jungle-expedition/rooms.gd")
const W: float=640
const H: float=248
const FLOOR: float=216
const HALF:=Vector2(8,10)
const SPEED: float=130
const JUMP: float=-235
var difficulty: int=1
var score: int=0
var lives: int=3
var region: int=1
var room: int=0
var checkpoint: int=0
var checkpoint_set: bool=false
var collected: Dictionary={}
var visited: Dictionary={}
var time: float=0
var bonus: float=210
var pos:=Vector2(36,206)
var vel:=Vector2.ZERO
var grounded: bool=true
var coyote: float=0.09
var buffer: float=0
var immune: float=0
var facing: int=1
var climbing: bool=false
var ladder_progress: float=0
var transition_cd: float=0
var on_bridge: bool=false
var bridge_x: float=0
var bridge_previous: float=0
var collapse: float=0
var gap:=Rect2()
var hazard: bool=false
var hazard_pos:=Vector2.ZERO
func create(_rng: RandomNumberGenerator,mode: String) -> void:
	difficulty=["easy","normal","hard"].find(mode)
	score=0
	lives=[4,3,2][difficulty]
	region=1
	collected.clear()
	visited.clear()
	start_region()
func start_region() -> void:
	room=0
	checkpoint=0
	checkpoint_set=false
	time=0
	bonus=[240,210,180][difficulty]
	enter(0,36)
func enter(id: int,x: float) -> void:
	room=id
	visited[(region-1)*8+room]=true
	pos=Vector2(x,FLOOR-HALF.y)
	vel=Vector2.ZERO
	grounded=true
	coyote=0.09
	buffer=0
	climbing=false
	ladder_progress=0
	on_bridge=false
	transition_cd=0.25
	collapse=0
	var spec: Array=Data.ROOMS[(region-1)*8+room]
	gap=Rect2(float(spec[1]),FLOOR,48,32) if spec[0]==1 else Rect2()
	hazard=spec[2]==1
	bridge_x=gap.get_center().x
	bridge_previous=bridge_x
	hazard_pos=Vector2(500,FLOOR-12)
func count_region() -> int:
	var total: int=0
	for id: int in Data.ARTIFACTS:
		total+=int(collected.has((region-1)*8+id))
	return total
func neighbors(id: int) -> Array[int]:
	var out: Array[int]=[]
	if id%4>0: out.append(id-1)
	if id%4<3: out.append(id+1)
	if id in Data.LADDERS: out.append(id+4 if id<4 else id-4)
	return out
func artifact_pos() -> Vector2:
	return Vector2(550,FLOOR-20)
func lose() -> Dictionary:
	lives-=1
	if lives<=0:
		return {"score":score,"progress":region,"reason":"lost"}
	enter(checkpoint,80 if checkpoint_set else 36)
	immune=1.2
	return {}
func step(input: Dictionary,dt: float,_rng: RandomNumberGenerator) -> Dictionary:
	time+=dt
	bonus=maxf(0,bonus-dt)
	immune=maxf(0,immune-dt)
	transition_cd=maxf(0,transition_cd-dt)
	var axis:=Vector2(float(int(input.get("right",false))-int(input.get("left",false))),float(int(input.get("down",false))-int(input.get("up",false))))
	var analog: Dictionary=input.get("analog",{})
	if analog.has("stick"):
		var delta: Vector2=analog.stick.delta
		axis=Vector2.ZERO if delta.length()<8 else delta.normalized()
	if absf(axis.x)>0.15:
		facing=1 if axis.x>0 else -1
	if input.get("pressed",{}).has("fire"):
		buffer=0.10
	else:
		buffer=maxf(0,buffer-dt)
	if grounded:
		coyote=0.09
	else:
		coyote=maxf(0,coyote-dt)
	if not gap.size.is_zero_approx():
		bridge_previous=bridge_x
		bridge_x=gap.get_center().x+sin(time*1.4)*12
		if on_bridge:
			pos.x+=bridge_x-bridge_previous
			collapse+=dt
		else:
			collapse=maxf(0,collapse-dt)
	var ladder: bool=room in Data.LADDERS and absf(pos.x-320)<17
	# Stick direction alone is sufficient; both directions take the same time.
	var ladder_direction: float=1.0 if room<4 else -1.0
	if ladder and axis.y*ladder_direction>0.6:
		climbing=true
		grounded=false
		vel=Vector2.ZERO
		pos.x=320
		ladder_progress=minf(1.0,ladder_progress+95.0*dt/(FLOOR-HALF.y-48))
		pos.y=lerpf(FLOOR-HALF.y,48.0,ladder_progress)
		if ladder_progress>=1 and transition_cd<=0:
			enter(room+4 if room<4 else room-4,320)
			return {}
	else:
		climbing=false
		ladder_progress=0
		if buffer>0 and coyote>0:
			vel.y=JUMP
			buffer=0
			coyote=0
			grounded=false
			on_bridge=false
		vel.x=axis.x*SPEED
		vel.y=minf(280,vel.y+640*dt)
		var old:=pos
		pos+=vel*dt
		var over_gap: bool=gap.size.x>0 and pos.x>gap.position.x+5 and pos.x<gap.end.x-5
		var bridge_safe: bool=over_gap and absf(pos.x-bridge_x)<14 and collapse<1.0
		grounded=false
		on_bridge=false
		if vel.y>=0 and old.y+HALF.y<=FLOOR+0.01 and pos.y+HALF.y>=FLOOR and (not over_gap or bridge_safe):
			pos.y=FLOOR-HALF.y
			vel.y=0
			grounded=true
			on_bridge=bridge_safe
		if pos.y>H+HALF.y:
			return lose()
	if pos.x<HALF.x:
		if room%4>0 and transition_cd<=0:
			enter(room-1,W-36)
			return {}
		pos.x=HALF.x
	if pos.x>W-HALF.x:
		if room%4<3 and transition_cd<=0:
			enter(room+1,36)
			return {}
		pos.x=W-HALF.x
	if hazard:
		var hazard_center: float=140 if gap.size.x>0 and gap.position.x>350 else 450
		hazard_pos=Vector2(hazard_center+sin(time*1.2)*20,FLOOR-12)
		if immune<=0 and pos.distance_to(hazard_pos)<18:
			return lose()
	var id: int=(region-1)*8+room
	if room in Data.ARTIFACTS and not collected.has(id) and pos.distance_to(artifact_pos())<22:
		collected[id]=true
		score+=350
	if room==4 and not checkpoint_set and pos.distance_to(Vector2(80,FLOOR-HALF.y))<30 and input.get("action",false):
		checkpoint=4
		checkpoint_set=true
	if room==0 and pos.x<80 and input.get("action",false) and count_region()==4:
		score+=700+int(floor(bonus*2))
		if region==3:
			return {"score":score,"progress":region,"reason":"victory"}
		region+=1
		start_region()
	return {}
