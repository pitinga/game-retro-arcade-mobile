extends RefCounted
const Geo = preload("res://core/geometry.gd")
const W: float=360.0
const H: float=464.0
const R: float=0.014*W
const PADDLE_Y: float=0.90*H
var score: int=0
var lives: int=3
var phase: int=1
var difficulty: int=1
var paddle: float=W/2
var ball:=Vector2(W/2,PADDLE_Y-10)
var velocity:=Vector2.ZERO
var serving: bool=true
var serve_delay: float=0.0
var blocks: Array[Dictionary]=[]
var drops: Array[Dictionary]=[]
var wide_timer: float=0.0
var slow_timer: float=0.0
var drop_cooldown: float=0.0
var destroyed: int=0
var speed: float=0.0
var drag_id: int=-999
var drag_start: float=0.0
func create(rng: RandomNumberGenerator,level: String) -> void:
	difficulty=["easy","normal","hard"].find(level)
	lives=[5,3,2][difficulty]
	score=0
	phase=1
	paddle=W/2
	build_level(rng)
func paddle_width() -> float:
	return float([0.24,0.20,0.16][difficulty])*W*(1.25 if wide_timer>0 else 1.0)
func paddle_rect() -> Rect2:
	return Rect2(paddle-paddle_width()/2,PADDLE_Y,paddle_width(),10)
func base_speed() -> float:
	return float([0.65,0.78,0.90][difficulty])*H
func build_level(rng: RandomNumberGenerator) -> void:
	blocks.clear()
	drops.clear()
	wide_timer=0
	slow_timer=0
	drop_cooldown=0
	destroyed=0
	speed=minf(base_speed()+0.08*H*mini(2,int((phase-1)/10.0)),1.5*H)
	var pattern: int=(phase-1)%10 if phase<=30 else rng.randi_range(0,9)
	var tier: int=mini(2,int((phase-1)/10.0))
	for row in range(6):
		for col in range(9):
			var center:=absf(float(col)-4.0)
			var include: bool=true
			match pattern:
				0: include=center<=float(row+1)
				1: include=center<=float(5-row)
				2: include=(row+col)%3!=0
				3: include=row==0 or row==5 or col in [0,8] or (row==2 and center<=2)
				4: include=absf(float(row)-2.5)+center<=4.5
				5: include=(col+row)%2==0 or row==5
				6: include=col<=row+1 or col>=8-row
				7: include=row%2==0 or col in [1,4,7]
				8: include=center>=float(row)*0.65 or row==0
				9: include=(col+2*row)%5!=0
			if not include:
				continue
			var x:=10.0+float(col)*38.0+(2.0 if tier==1 and row%2==1 else 0.0)
			var y:=28.0+float(row)*25.0+float(tier)*6.0
			var hp:=1+mini(tier,(row+col+phase)%3)
			blocks.append({"id":row*9+col,"rect":Rect2(x,y,34,20),"hp":hp,"initial":hp})
	serving=true
	serve_delay=0.8
	velocity=Vector2.ZERO
	ball=Vector2(paddle,PADDLE_Y-R-0.1)
	drag_id=-999
func limit_speed() -> void:
	if velocity.length_squared()<=0:
		velocity=Vector2.UP*speed
	var target:=speed*(0.8 if slow_timer>0 else 1.0)
	velocity=velocity.normalized()*target
	if absf(velocity.y)<target*0.25:
		var sy: float=-1 if velocity.y<=0 else 1
		var sx: float=-1 if velocity.x<0 else 1
		velocity=Vector2(sx*sqrt(1.0-0.25*0.25),sy*0.25)*target
func hit_block(index: int,rng: RandomNumberGenerator) -> void:
	blocks[index].hp-=1
	if blocks[index].hp>0:
		return
	var b: Dictionary=blocks[index]
	score+=int(b.initial)*50
	destroyed+=1
	if destroyed%5==0:
		speed=minf(speed*1.03,1.5*H)
	if phase>3 and drop_cooldown<=0 and rng.randf()<0.15:
		drops.append({"pos":b.rect.get_center(),"kind":rng.randi_range(0,1)})
		drop_cooldown=10
	blocks.remove_at(index)
func move_paddle(input: Dictionary,dt: float) -> void:
	var desired:=paddle
	var analog: Dictionary=input.get("analog",{})
	if analog.has("paddle"):
		var p: Dictionary=analog.paddle
		if drag_id!=p.id:
			drag_id=p.id
			drag_start=paddle
		desired=drag_start+float(p.delta.x)
	else:
		drag_id=-999
		desired+=float(int(input.get("right",false))-int(input.get("left",false)))*2*W*dt
	paddle=clampf(move_toward(paddle,desired,2*W*dt),paddle_width()/2,W-paddle_width()/2)
func step(input: Dictionary,dt: float,rng: RandomNumberGenerator) -> Dictionary:
	wide_timer=maxf(0,wide_timer-dt)
	slow_timer=maxf(0,slow_timer-dt)
	drop_cooldown=maxf(0,drop_cooldown-dt)
	move_paddle(input,dt)
	for i in range(drops.size()-1,-1,-1):
		drops[i].pos+=Vector2(0,110*dt)
		var point: Vector2=drops[i].pos
		if paddle_rect().grow(7).has_point(point):
			if drops[i].kind==0:
				wide_timer=10
			else:
				slow_timer=8
			drops.remove_at(i)
		elif point.y>H:
			drops.remove_at(i)
	if serving:
		ball=Vector2(paddle,PADDLE_Y-R-0.1)
		serve_delay=maxf(0,serve_delay-dt)
		var pressed: Dictionary=input.get("pressed",{})
		if serve_delay<=0 and (pressed.has("fire") or pressed.has("action")):
			serving=false
			velocity=Vector2(rng.randf_range(-0.45,0.45),-1).normalized()*speed
		return {}
	limit_speed()
	var remaining:=dt
	var damaged: Dictionary={}
	for _iteration in range(8):
		if remaining<=0.0000001:
			break
		var delta:=velocity*remaining
		var earliest: float=1.0
		var normal:=Vector2.ZERO
		var hit_index: int=-1
		var kind: String=""
		for wall: Dictionary in [{"axis":0,"bound":R,"direction":-1,"normal":Vector2.RIGHT},{"axis":0,"bound":W-R,"direction":1,"normal":Vector2.LEFT},{"axis":1,"bound":R,"direction":-1,"normal":Vector2.DOWN},{"axis":1,"bound":H+R,"direction":1,"normal":Vector2.UP}]:
			var axis: int=wall.axis
			if delta[axis]*int(wall.direction)<=0:
				continue
			var t: float=(float(wall.bound)-ball[axis])/delta[axis]
			if t>=0 and t<=earliest:
				earliest=t
				normal=wall.normal
				kind="bottom" if axis==1 and wall.direction==1 else "wall"
		if velocity.y>0:
			var hit:=Geo.sweep_circle_rect(ball,delta,R,paddle_rect())
			if not hit.is_empty() and hit.time<=earliest:
				earliest=hit.time
				normal=hit.normal
				kind="paddle"
		for idx in blocks.size():
			var hit:=Geo.sweep_circle_rect(ball,delta,R,blocks[idx].rect)
			if not hit.is_empty() and hit.time<earliest:
				earliest=hit.time
				normal=hit.normal
				hit_index=idx
				kind="block"
		ball+=delta*earliest
		if kind.is_empty():
			break
		if kind=="bottom":
			lives-=1
			if lives<=0:
				return {"score":score,"progress":phase,"reason":"lost"}
			serving=true
			serve_delay=0.8
			velocity=Vector2.ZERO
			return {}
		if kind=="paddle":
			var angle:=clampf((ball.x-paddle)/(paddle_width()/2),-1,1)*deg_to_rad(65.0)
			velocity=Vector2(sin(angle),-cos(angle))*speed
			normal=Vector2.UP
		else:
			if velocity.dot(normal)<0:
				velocity=velocity.bounce(normal)
			if kind=="block":
				var id: int=blocks[hit_index].id
				if not damaged.has(id):
					damaged[id]=true
					hit_block(hit_index,rng)
		ball+=normal*0.02
		limit_speed()
		remaining*=maxf(0,1-earliest)
		if blocks.is_empty():
			score+=250
			phase+=1
			build_level(rng)
			return {}
	return {}
