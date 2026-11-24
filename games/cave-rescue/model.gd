extends RefCounted
const Data=preload("res://games/cave-rescue/levels.gd")
const W: float=640
const H: float=248
const TILE: float=24
const HALF:=Vector2(8,9)
var difficulty: int=1
var score: int=0
var lives: int=3
var level: int=1
var energy: float=100
var charges: int=3
var grace: float=1.5
var pos:=Vector2(36,207)
var vel:=Vector2.ZERO
var grounded: bool=false
var facing: int=1
var time: float=0
var cut_timer: float=0
var cut_cell:=Vector2i(-1,-1)
var pulse_cd: float=0
var pulse_flash: float=0
var rescue_hold: float=0
var cells: Dictionary={}
var batteries: Array[Vector2i]=[]
var enemies: Array[Vector2i]=[]
var hazards: Dictionary={}
var rewarded: Dictionary={}
var scientist:=Vector2(588,207)
func create(_rng: RandomNumberGenerator,mode: String) -> void:
	difficulty=["easy","normal","hard"].find(mode)
	score=0
	lives=[4,3,2][difficulty]
	level=1
	rewarded.clear()
	load_level()
func load_level() -> void:
	cells.clear()
	batteries.clear()
	enemies.clear()
	hazards.clear()
	var rows: Array=Data.LEVELS[level-1]
	for y in range(rows.size()):
		var row: String=rows[y]
		for x in range(row.length()):
			var cell:=Vector2i(x,y)
			match row[x]:
				"#","B": cells[cell]=row[x]
				"+": batteries.append(cell)
				"E": enemies.append(cell)
				"V","W": hazards[cell]=row[x]
				"S": pos=Vector2(x*24+12,207)
				"R": scientist=Vector2(x*24+12,207)
	vel=Vector2.ZERO
	grounded=true
	facing=1
	energy=100
	charges=[4,3,2][difficulty]
	grace=1.5
	time=0
	cut_timer=0
	cut_cell=Vector2i(-1,-1)
	pulse_cd=0
	pulse_flash=0
	rescue_hold=0
func center(cell: Vector2i) -> Vector2:
	return Vector2(cell)*TILE+Vector2.ONE*TILE/2
func hitbox(point: Vector2) -> Rect2:
	return Rect2(point-HALF,HALF*2)
func solid(point: Vector2) -> bool:
	var box:=hitbox(point)
	var lo:=Vector2i(floor(box.position.x/TILE),floor(box.position.y/TILE))
	var hi:=Vector2i(floor((box.end.x-0.001)/TILE),floor((box.end.y-0.001)/TILE))
	for y in range(lo.y,hi.y+1):
		for x in range(lo.x,hi.x+1):
			if cells.has(Vector2i(x,y)):
				return true
	return false
func move_axis(amount: float,horizontal: bool) -> bool:
	# Fixed-step conservative swept AABB: <=1u substeps, never skip a tile.
	var count:=maxi(1,ceili(absf(amount)))
	var delta:=amount/float(count)
	for i in range(count):
		var next:=pos+(Vector2(delta,0) if horizontal else Vector2(0,delta))
		if solid(next) or next.x<HALF.x or next.y<HALF.y:
			return false
		pos=next
	return true
func award(key: String,value: int) -> void:
	if not rewarded.has(key):
		rewarded[key]=true
		score+=value
func lose() -> Dictionary:
	lives-=1
	if lives<=0:
		return {"score":score,"progress":level,"reason":"lost"}
	load_level()
	return {}
func cut_target() -> Vector2i:
	var best:=Vector2i(-1,-1)
	var distance: float=32
	for cell: Vector2i in cells:
		if cells[cell]!="B":
			continue
		var d:=center(cell)-pos
		if d.x*facing>=0 and d.length()<distance:
			distance=d.length()
			best=cell
	return best
func vapor_active() -> bool:
	return fposmod(time,4.0)>=2.8
func vapor_warning() -> bool:
	return fposmod(time,4.0)>=1.8 and not vapor_active()
func pulse() -> void:
	pulse_cd=0.3
	pulse_flash=0.12
	var target:=pos+Vector2(facing*140,0)
	var limit:=140.0
	for cell: Vector2i in cells:
		var d:=center(cell)-pos
		if d.x*facing>0 and absf(d.y)<12:
			limit=minf(limit,absf(d.x)-12)
	for i in range(enemies.size()-1,-1,-1):
		var cell:=enemies[i]
		var d:=center(cell)-pos
		if d.x*facing>=0 and absf(d.x)<=limit and absf(d.y)<17:
			enemies.remove_at(i)
			award("enemy:"+str(cell),75)
			break
func step(input: Dictionary,dt: float,_rng: RandomNumberGenerator) -> Dictionary:
	time+=dt
	pulse_cd=maxf(0,pulse_cd-dt)
	pulse_flash=maxf(0,pulse_flash-dt)
	var axis:=float(int(input.get("right",false))-int(input.get("left",false)))
	if axis!=0:
		facing=1 if axis>0 else -1
	var jet: bool=(input.get("fire",false) or input.get("up",false)) and energy>0
	vel.x=axis*145 if axis!=0 else move_toward(vel.x,0,900*dt if grounded else 420*dt)
	vel.y=clampf(vel.y+(520-760*int(jet))*dt,-160,160)
	energy=maxf(0,energy-(0.8+float([7,9,11][difficulty])*int(jet))*dt)
	if not move_axis(vel.x*dt,true):
		vel.x=0
	grounded=false
	if not move_axis(vel.y*dt,false):
		grounded=vel.y>=0
		vel.y=0
	if input.get("action",false) and pulse_cd<=0 and energy>0:
		pulse()
	if input.get("pressed",{}).has("secondary") and cut_timer<=0 and charges>0 and energy>0:
		var cell:=cut_target()
		if cell.x>=0:
			cut_cell=cell
			cut_timer=0.65
			charges-=1
	if cut_timer>0:
		cut_timer=maxf(0,cut_timer-dt)
		if cut_timer<=0:
			var danger:=center(cut_cell)
			cells.erase(cut_cell)
			cut_cell=Vector2i(-1,-1)
			if pos.distance_to(danger)<36:
				return lose()
	for i in range(batteries.size()-1,-1,-1):
		var cell:=batteries[i]
		if pos.distance_to(center(cell))<17:
			energy=minf(100,energy+35)
			batteries.remove_at(i)
			award("battery:"+str(cell),100)
	for cell: Vector2i in enemies:
		if pos.distance_to(center(cell))<17:
			return lose()
	for cell: Vector2i in hazards:
		if hitbox(pos).intersects(Rect2(Vector2(cell)*TILE,Vector2.ONE*TILE)) and (hazards[cell]=="W" or vapor_active()):
			return lose()
	if energy<=0:
		grace=maxf(0,grace-dt)
		if grace<=0:
			return lose()
	else:
		grace=1.5
	if pos.distance_to(scientist)<20 and (input.get("action",false) or input.get("fire",false)):
		rescue_hold+=dt
		if rescue_hold>=0.6-0.000001:
			score+=600+int(floor(energy*3))
			if level==20:
				return {"score":score,"progress":level,"reason":"victory"}
			level+=1
			rewarded.clear()
			load_level()
	else:
		rescue_hold=0
	return {}
