extends RefCounted
const W: float=360.0
const H: float=464.0
var difficulty: int=1
var score: int=0
var day: int=1
var integrity: int=5
var elapsed: float=0.0
var countdown: float=3.0
var speed: float=0.0
var distance: float=0.0
var lateral: float=0.0
var passes: int=0
var goal: int=24
var invulnerable: float=0.0
var spawn_cd: float=0.0
var next_id: int=0
var safe_lane: int=1
var weather_start: float=0.0
var fog: bool=false
var ice: bool=false
var auto_accel: bool=false
var drag_id: int=-999
var drag_start: float=0.0
var rivals: Array[Dictionary]=[]
var lanes: Array[float]=[-0.65,0.0,0.65]
func create(rng: RandomNumberGenerator,level: String) -> void:
	difficulty=["easy","normal","hard"].find(level)
	score=0
	day=1
	integrity=[6,5,4][difficulty]
	distance=0
	speed=0
	lateral=0
	next_id=0
	begin_day(rng)
func begin_day(rng: RandomNumberGenerator) -> void:
	elapsed=0
	countdown=3
	passes=0
	goal=mini(55,int([18,24,30][difficulty])+4*(day-1))
	safe_lane=rng.randi_range(0,2)
	weather_start=rng.randf_range(32,60)
	fog=false
	ice=false
	invulnerable=0
	spawn_cd=0.3
	rivals.clear()
	drag_id=-999
func steering() -> float:
	return float([1.7,1.5,1.3][difficulty])*(0.6 if ice else 1.0)
func curve(z: float) -> float:
	return sin(z/180.0+day*0.7)*0.22+sin(z/390.0)*0.12
func phase() -> int:
	return 0 if elapsed<30 else (1 if elapsed<55 else (2 if elapsed<75 else 3))
func spawn(rng: RandomNumberGenerator) -> void:
	# Reserve one uninterrupted lane per day; traffic chooses the other two.
	var available: Array[int]=[]
	for i in range(3):
		if i!=safe_lane:
			var clear: bool=true
			for car: Dictionary in rivals:
				if car.lane==i and absf(float(car.z)-95)<24:
					clear=false
			if clear:
				available.append(i)
	if available.is_empty() or rivals.size()>=16:
		return
	var lane: int=available[rng.randi_range(0,available.size()-1)]
	next_id+=1
	rivals.append({"id":next_id,"lane":lane,"z":95.0,"speed":rng.randf_range(45,100)/3.6,"counted":false,"hit":false})
func step(input: Dictionary,dt: float,rng: RandomNumberGenerator) -> Dictionary:
	if input.get("pressed",{}).has("secondary"):
		auto_accel=not auto_accel
	var braking: bool=input.get("down",false)
	var accelerating: bool=input.get("up",false) or auto_accel
	speed=clampf(speed+( -15.0 if braking else (8.0 if accelerating else -2.0))*dt,0,200.0/3.6)
	var steer:=float(int(input.get("right",false))-int(input.get("left",false)))
	var analog: Dictionary=input.get("analog",{})
	if analog.has("paddle"):
		var pointer: Dictionary=analog.paddle
		if drag_id!=pointer.id:
			drag_id=pointer.id
			drag_start=lateral
		steer=clampf((drag_start+float(pointer.delta.x)/140-lateral)*6,-1,1)
	else:
		drag_id=-999
	lateral=clampf(lateral+steer*steering()*dt,-1.15,1.15)
	if absf(lateral)>1.0:
		speed=maxf(0,speed-12*dt)
	if countdown>0:
		countdown=maxf(0,countdown-dt)
		return {}
	elapsed+=dt
	fog=elapsed>=weather_start and elapsed<weather_start+7
	ice=elapsed>=weather_start+10 and elapsed<weather_start+18
	distance+=speed*dt
	invulnerable=maxf(0,invulnerable-dt)
	spawn_cd-=dt
	if spawn_cd<=0:
		spawn(rng)
		spawn_cd=0.92
	for i in range(rivals.size()-1,-1,-1):
		var car: Dictionary=rivals[i]
		var before: float=car.z
		var after:=before+(float(car.speed)-speed)*dt
		car.z=after
		var separated:=absf(lateral-lanes[car.lane])>=0.32
		# Swept longitudinal overlap, before scoring at the crossing.
		if not separated and minf(before,after)<=3 and maxf(before,after)>=-3:
			car.hit=true
			if invulnerable<=0:
				integrity-=1
				speed*=0.55
				invulnerable=1.2
				if integrity<=0:
					return {"score":score,"progress":day,"reason":"lost"}
		if before>0 and after<=0 and not car.counted:
			car.counted=true
			if separated and not car.hit:
				passes+=1
				score+=100
		if after< -30 or after>160:
			rivals.remove_at(i)
	if elapsed>=90.0-0.000001:
		if passes<goal:
			return {"score":score,"progress":day,"reason":"goal"}
		score+=500+integrity*50
		integrity=mini(int([6,5,4][difficulty]),integrity+1)
		day+=1
		begin_day(rng)
	return {}
