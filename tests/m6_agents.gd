extends RefCounted
var old_level: int=-1
var flight_end: float=-1
var flight_height: float=170
var cut_exit: float=-1
var deep_lives: int=-1
var jump_target: float=-1
var jump_region: int=-1
var jump_room: int=-1
var jump_lives: int=-1
func deep_input(m: RefCounted) -> Dictionary:
	if old_level!=m.level or deep_lives!=m.lives:
		old_level=m.level
		deep_lives=m.lives
		cut_exit=-1
		flight_end=-1
		flight_height=180
	var pulse: bool=false
	for cell: Vector2i in m.enemies:
		var delta: Vector2=m.enemy_pos(cell)-m.pos
		if delta.x>=0 and delta.x<=125 and absf(delta.y)<17:
			pulse=true
	if m.cut_timer>0:
		cut_exit=m.center(m.cut_cell).x+25
		flight_end=-1
		flight_height=180
		return {"left":m.pos.x>m.center(m.cut_cell).x-65,"action":pulse}
	# The cut removes only the floor tile. Stay grounded until the whole hitbox
	# clears the remaining overhead wall; premature jet use traps it under the lintel.
	if cut_exit>=0:
		if m.pos.x<cut_exit:
			return {"right":true,"action":pulse}
		cut_exit=-1
	var near_gate: float=INF
	for cell: Vector2i in m.cells:
		if m.cells[cell]=="B" and m.cells.has(Vector2i(cell.x,0)):
			var x: float=m.center(cell).x
			if x>=m.pos.x:
				near_gate=minf(near_gate,x)
	if near_gate-m.pos.x<35:
		if absf(m.pos.y-207)>4:
			return {"action":pulse}
		if near_gate-m.pos.x<=30:
			return {"right":true,"action":pulse,"pressed":{"secondary":Vector2.ZERO}}
		return {"right":true,"action":pulse}
	if flight_end>=0 and m.pos.x>flight_end:
		flight_end=-1
	for cell: Vector2i in m.cells:
		if cell.y!=8 or m.cells[cell] not in ["#","B"] or cell.x in [0,25]:
			continue
		var x: float=m.center(cell).x
		# Don't attempt to fly through full-height gate.
		if m.cells.has(Vector2i(cell.x,0)):
			continue
		if x>=m.pos.x-22 and x-m.pos.x<78:
			var top: float=192
			for y in range(7,-1,-1):
				if m.cells.has(Vector2i(cell.x,y)):
					top=minf(top,y*24.0)
			flight_height=minf(flight_height,top-12)
			flight_end=maxf(flight_end,x+31)
	for cell: Vector2i in m.hazards:
		var x: float=m.center(cell).x
		if x>=m.pos.x-22 and x-m.pos.x<78:
			flight_height=minf(flight_height,180)
			flight_end=maxf(flight_end,x+31)
	if flight_end>=0:
		var jet: bool=m.pos.y>flight_height-8 or (m.vel.y>15 and m.pos.y>flight_height-35)
		return {"right":m.pos.y<flight_height,"fire":jet,"action":pulse}
	flight_height=180
	if m.pos.distance_to(m.scientist)<16:
		return {"action":pulse}
	if m.pos.x>m.scientist.x:
		return {"left":true,"action":pulse}
	return {"right":true,"action":pulse}
# Predict a jump using actual fixed-step kinematics, bridge phase, and moving hazards.
# No position changes are made to the live model: this only selects button inputs.
func jump_is_safe(m: RefCounted,target: float) -> bool:
	var dt: float=1.0/60
	var x: float=m.pos.x
	var y: float=m.pos.y
	var vy: float=m.JUMP
	var start_bridge: bool=m.on_bridge
	var bridge: float=m.bridge_x
	var elapsed: float=m.time
	for tick in range(50):
		elapsed+=dt
		var next_bridge: float=m.gap.get_center().x+sin(elapsed*1.4)*10
		# A supported player is carried once before the launch input is applied.
		if tick==0 and start_bridge:
			x+=next_bridge-bridge
		bridge=next_bridge
		var delta: float=target-x
		x+=signf(delta)*m.SPEED*dt if absf(delta)>m.SPEED*dt/2 else 0.0
		vy=minf(280,vy+640*dt)
		var old_y:=y
		y+=vy*dt
		if m.hazard:
			var center: float=140 if m.gap.size.x>0 and m.gap.position.x>350 else 450
			var patrol:=Vector2(center+sin(elapsed*1.2)*20,m.FLOOR-12)
			if Vector2(x,y).distance_to(patrol)<21:
				return false
		if m.overhead:
			var overhead:=Vector2(190+sin(elapsed*1.5)*30,150+sin(elapsed*2.2)*8)
			if Vector2(x,y).distance_to(overhead)<21:
				return false
		if vy>=0 and old_y+m.HALF.y<=m.FLOOR+0.01 and y+m.HALF.y>=m.FLOOR:
			var gap: bool=m.gap.size.x>0 and x>m.gap.position.x+5 and x<m.gap.end.x-5
			var supported: bool=absf(x-bridge)<21
			# A bridge landing has a tighter safety margin than the physics boundary.
			if gap and not supported:
				return false
			if m.hazard:
				var center: float=140 if m.gap.size.x>0 and m.gap.position.x>350 else 450
				var patrol:=Vector2(center+sin(elapsed*1.2)*20,m.FLOOR-12)
				if Vector2(x,m.FLOOR-m.HALF.y).distance_to(patrol)<27:
					return false
			return true
	return false
func plan_jump(m: RefCounted,direction: float,target: float) -> float:
	var best: float=-1
	# Candidate landing points span actual jump range; farthest safe progress wins.
	for distance in range(92,19,-4):
		var landing: float=m.pos.x+direction*distance
		if landing<9 or landing>m.W-9:
			continue
		if absf(target-m.pos.x)<distance-8:
			continue
		if jump_is_safe(m,landing):
			best=landing
			break
	return best
func emerald_input(m: RefCounted,naive: bool=false) -> Dictionary:
	var target: float=320
	var next: int=-1
	var direction: float=0
	if m.room in [1,3,5,7] and not m.collected.has((m.region-1)*8+m.room):
		target=m.artifact_pos().x
	else:
		match m.room:
			0:
				if m.count_region()==4:
					target=36
				else:
					next=1
			1: next=2
			2:
				if not m.collected.has((m.region-1)*8+3):
					next=3
				elif not m.collected.has((m.region-1)*8+7):
					next=6
				else:
					next=1
			3: next=2
			4:
				if m.count_region()==4:
					next=0
				else:
					next=5
			5: next=4
			6:
				if not m.collected.has((m.region-1)*8+7):
					next=7
				else:
					next=5
			7: next=6
		if next>=0:
			target=320 if absi(next-m.room)==4 else (-20.0 if next<m.room else 660.0)
	if m.room==0 and m.count_region()==4 and m.pos.x<70:
		return {"action":true}
	if next>=0 and absi(next-m.room)==4 and absf(m.pos.x-320)<9:
		return {"action":true,"down":next>m.room,"up":next<m.room}
	if jump_region!=m.region or jump_room!=m.room or jump_lives!=m.lives:
		jump_region=m.region
		jump_room=m.room
		jump_lives=m.lives
		jump_target=-1
	if not naive and not m.grounded and jump_target>=0:
		var delta: float=jump_target-m.pos.x
		return {"right":delta>m.SPEED/120,"left":delta<-m.SPEED/120}
	if m.grounded:
		jump_target=-1
	direction=signf(target-m.pos.x) if absf(target-m.pos.x)>5 else 0
	var result: Dictionary={"right":direction>0,"left":direction<0}
	if m.grounded and direction!=0:
		var edge: float=m.gap.position.x if direction>0 else m.gap.end.x
		var distance: float=(edge-m.pos.x)*direction
		var hazard_distance: float=(m.hazard_pos.x-m.pos.x)*direction
		if naive:
			if (m.gap.size.x>0 and distance>=0 and distance<=17) or (m.hazard and hazard_distance>=0 and hazard_distance<=38):
				result["pressed"]={"fire":Vector2.ZERO}
		elif m.on_bridge or (m.gap.size.x>0 and distance>=-5 and distance<=23) or (m.hazard and hazard_distance>=-5 and hazard_distance<=58):
			jump_target=plan_jump(m,direction,target)
			if jump_target>=0:
				result["pressed"]={"fire":Vector2.ZERO}
			else:
				# Advance only on safe ground; otherwise wait for a viable bridge/patrol phase.
				if m.on_bridge or (m.gap.size.x>0 and distance<=4 and distance>=-5) or (m.hazard and hazard_distance<=26 and hazard_distance>=-5):
					return {}
	return result
