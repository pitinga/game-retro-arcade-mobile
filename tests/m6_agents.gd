extends RefCounted
var old_level: int=-1
var flight_end: float=-1
var flight_height: float=170
func deep_input(m: RefCounted) -> Dictionary:
	if old_level!=m.level:
		old_level=m.level
		flight_end=-1
		flight_height=180
	var pulse: bool=false
	for cell: Vector2i in m.enemies:
		var delta: Vector2=m.enemy_pos(cell)-m.pos
		if delta.x>=0 and delta.x<=125 and absf(delta.y)<17:
			pulse=true
	if m.cut_timer>0:
		return {"left":m.pos.x>m.center(m.cut_cell).x-65,"action":pulse}
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
	direction=signf(target-m.pos.x) if absf(target-m.pos.x)>5 else 0
	var result: Dictionary={"right":direction>0,"left":direction<0}
	if m.grounded and direction!=0:
		var edge: float=m.gap.position.x if direction>0 else m.gap.end.x
		var distance: float=(edge-m.pos.x)*direction
		var hazard_distance: float=(m.hazard_pos.x-m.pos.x)*direction
		if (not naive and m.on_bridge) or (m.gap.size.x>0 and distance>=0 and distance<=17) or (m.hazard and hazard_distance>=0 and hazard_distance<=38):
			result["pressed"]={"fire":Vector2.ZERO}
	return result
