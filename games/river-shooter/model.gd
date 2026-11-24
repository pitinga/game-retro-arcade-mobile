extends RefCounted
const Geo=preload("res://core/geometry.gd")
const W: float=360.0
const H: float=464.0
const Y: float=0.78*H
const R: float=9.0
const SEG: float=H/3.0
var difficulty: int=1
var score: int=0
var lives: int=3
var sector: int=1
var energy: float=100.0
var distance: float=0.0
var length: float=5*H
var x: float=W/2
var vx: float=0.0
var immune: float=0.0
var fire_cd: float=0.0
var elapsed: float=0.0
var next_bonus: int=8000
var damage: bool=false
var route: int=0
var fork_z: float=-1.0
var drag_id: int=-999
var drag_start: float=0.0
var centers: Array[float]=[]
var widths: Array[float]=[]
var objects: Array[Dictionary]=[]
var shots: Array[Dictionary]=[]
var hostile: Array[Dictionary]=[]
var consumed: Dictionary={}
var rewarded: Dictionary={}
func create(rng: RandomNumberGenerator,level: String) -> void:
	difficulty=["easy","normal","hard"].find(level)
	score=0
	lives=[4,3,2][difficulty]
	sector=1
	next_bonus=8000
	generate_sector(rng,W/2)
func generate_sector(rng: RandomNumberGenerator,start_center: float) -> void:
	centers=[start_center]
	widths=[W*0.56]
	length=float(rng.randi_range(12,18))*SEG
	var count:=int(length/SEG)+4
	for i in range(1,count):
		centers.append(clampf(centers[-1]+rng.randf_range(-36,36),100,260))
		widths.append(rng.randf_range(0.46,0.60)*W)
	objects.clear()
	consumed.clear()
	rewarded.clear()
	# Alternating energy lanes; center is not a safe autopilot route.
	var id: int=0
	var z: float=0.65*H
	while z<length:
		id+=1
		var lane:=corridor(z)
		var offset: float=0.0 if sector==1 else (-1.0 if id%2==1 else 1.0)*lane.y*0.30
		objects.append({"id":id,"z":z,"x":lane.x+offset,"kind":"energy","cooldown":0.0,"side":0.0})
		z+=0.72*H
	z=1.0*H
	while z<length-0.1*H:
		id+=1
		var lane:=corridor(z)
		var side: float=0.0 if sector>=2 and id%2==0 else (-1.0 if id%3==0 else 1.0)
		var kind: String="turret" if sector>=4 and id%4==0 else ("patrol" if sector>=2 and id%3==0 and side!=0 else "drone")
		objects.append({"id":id,"z":z,"x":lane.x+side*lane.y*0.34,"kind":kind,"cooldown":1.0,"side":side})
		z+=rng.randf_range(0.32,0.52)*H*maxf(0.62,1.0-0.04*maxi(0,sector-4))
	fork_z=-1.0
	if sector>=3:
		var fork:=length*0.55
		fork_z=fork
		var lane:=corridor(fork)
		for side: int in [-1,1]:
			id+=1
			objects.append({"id":id,"z":fork,"x":lane.x+side*lane.y*0.24,"kind":"beacon","cooldown":0.0,"side":float(side)})
	distance=0
	elapsed=0
	energy=100
	x=start_center
	vx=0
	immune=1.2
	fire_cd=0
	damage=false
	route=0
	drag_id=-999
	shots.clear()
	hostile.clear()
func corridor(z: float) -> Vector2:
	var pos:=clampf(z/SEG,0,float(centers.size()-1)-0.00001)
	var i:=int(floor(pos))
	return Vector2(lerpf(centers[i],centers[i+1],pos-i),lerpf(widths[i],widths[i+1],pos-i))
func screen_y(z: float) -> float:
	return Y-(z-distance)
func points(value: int) -> void:
	score+=value
	while score>=next_bonus:
		lives=mini(5,lives+1)
		next_bonus+=8000
func collect(o: Dictionary) -> void:
	if consumed.has(o.id):
		return
	consumed[o.id]=true
	if o.kind=="energy":
		energy=minf(100,energy+38)
		if not rewarded.has(o.id):
			rewarded[o.id]=true
			points(20)
	elif o.kind=="beacon" and route==0:
		route=int(o.side)
		if not rewarded.has(-1):
			rewarded[-1]=true
			points(60 if route<0 else 90)
		# Choice changes scroll/energy tradeoff over remainder of sector.
func lose() -> Dictionary:
	lives-=1
	damage=true
	if lives<=0:
		return {"score":score,"progress":sector,"reason":"lost"}
	# Same sector checkpoint, restore cells and choice without awarding points twice.
	route=0
	for o: Dictionary in objects:
		if o.kind in ["energy","beacon"]:
			consumed.erase(o.id)
	distance=0
	elapsed=0
	x=centers[0]
	vx=0
	energy=100
	immune=1.2
	fire_cd=0
	drag_id=-999
	shots.clear()
	hostile.clear()
	return {}
func step(input: Dictionary,dt: float,rng: RandomNumberGenerator) -> Dictionary:
	var boost: bool=input.get("up",false)
	var brake: bool=input.get("down",false) and not boost
	var scroll:=minf(0.52,float([0.24,0.30,0.36][difficulty])+0.015*(sector-1))*H
	scroll*=1.35 if boost else (0.7 if brake else 1.0)
	if route>0:
		scroll*=1.10
	distance+=scroll*dt
	elapsed+=dt
	energy=maxf(0,energy-float([4,5,6][difficulty])*(1.25 if boost else 1.0)*(1.20 if route>0 else 1.0)*dt)
	immune=maxf(0,immune-dt)
	fire_cd=maxf(0,fire_cd-dt)
	var direction:=float(int(input.get("right",false))-int(input.get("left",false)))
	var analog: Dictionary=input.get("analog",{})
	if analog.has("paddle"):
		var pointer: Dictionary=analog.paddle
		if drag_id!=pointer.id:
			drag_id=pointer.id
			drag_start=x
		direction=clampf((drag_start+float(pointer.delta.x)-x)/30,-1,1)
	else:
		drag_id=-999
	vx=move_toward(vx,direction*0.85*W,3*W*dt)
	x+=vx*dt
	var lane:=corridor(distance)
	var left:=lane.x-lane.y/2+R
	var right:=lane.x+lane.y/2-R
	var fatal: bool=energy<=0 or (immune<=0 and (x<left or x>right))
	x=clampf(x,left,right)
	if input.get("fire",false) and fire_cd<=0 and shots.size()<12:
		shots.append({"pos":Vector2(x,Y-12)})
		fire_cd=0.24
	var visible: int=0
	for o: Dictionary in objects:
		if consumed.has(o.id):
			continue
		var sy:=screen_y(o.z)
		if sy<0 or sy>H:
			continue
		if o.kind in ["energy","beacon"]:
			if Vector2(x,Y).distance_to(Vector2(o.x,sy))<R+11:
				collect(o)
			continue
		visible+=1
		if visible>10 or elapsed<2:
			continue
		var center:=corridor(o.z)
		var ox: float=o.x
		if o.kind=="patrol":
			ox=center.x+float(o.side)*center.y*(0.31+0.05*sin(elapsed*2+float(o.id)))
		o["draw_x"]=ox
		if immune<=0 and Vector2(x,Y).distance_to(Vector2(ox,sy))<R+10:
			fatal=true
		o.cooldown=maxf(0,float(o.cooldown)-dt)
		if o.kind=="turret" and o.cooldown<=0 and sy>60 and sy<Y-0.6*H*0.36 and hostile.size()<6:
			hostile.append({"pos":Vector2(ox,sy)})
			o.cooldown=1.5
	for i in range(shots.size()-1,-1,-1):
		var start: Vector2=shots[i].pos
		var delta:=Vector2(0,-1.6*H*dt)
		var best: float=2
		var target: Dictionary={}
		for o: Dictionary in objects:
			if consumed.has(o.id) or o.kind in ["energy","beacon"] or elapsed<2:
				continue
			var sy:=screen_y(o.z)
			if sy<0 or sy>H:
				continue
			var hit:=Geo.segment_circle(start,delta,Vector2(o.get("draw_x",o.x),sy),11)
			if hit>=0 and hit<best:
				best=hit
				target=o
		if not target.is_empty():
			consumed[target.id]=true
			points({"drone":40,"patrol":90,"turret":140}[target.kind])
			shots.remove_at(i)
		else:
			shots[i].pos=start+delta
			if shots[i].pos.y<0:
				shots.remove_at(i)
	for i in range(hostile.size()-1,-1,-1):
		var start: Vector2=hostile[i].pos
		var delta:=Vector2(0,0.55*H*dt)
		if Geo.segment_circle(start,delta,Vector2(x,Y),R+3)>=0:
			if immune<=0:
				fatal=true
			hostile.remove_at(i)
		else:
			hostile[i].pos=start+delta
			if hostile[i].pos.y>H:
				hostile.remove_at(i)
	if fatal:
		return lose()
	if distance>=length:
		points(350+(0 if damage else 100))
		var end_center:=corridor(length).x
		var old_x:=x
		var old_energy:=energy
		sector+=1
		generate_sector(rng,end_center)
		var next_lane:=corridor(0)
		x=clampf(old_x,next_lane.x-next_lane.y/2+R,next_lane.x+next_lane.y/2-R)
		energy=old_energy
	return {}
