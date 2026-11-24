extends RefCounted
# Reference inputs only: never mutate score, position or outcome during a run.
static func abyss_input(m: RefCounted) -> Dictionary:
	if m.wave_wait>0:
		return {}
	var target:=Vector2(m.pos.x,0.07*m.H)
	if m.cargo==0 and m.oxygen>35:
		var best: float=INF
		for c: Dictionary in m.capsules:
			if c.pos.y>0.40*m.H:
				continue
			var dist:=Vector2(m.pos).distance_to(c.pos)
			if dist<best:
				best=dist
				target=c.pos
		if best==INF and m.pos.y<=0.10*m.H:
			return {}
	var delta:=target-Vector2(m.pos)
	if delta.length()<4:
		return {}
	var axis:=Vector2(delta.x/(0.48*m.W),delta.y/(0.65*m.H))
	if m.wave>=3 and m.pos.y>0.2*m.H:
		axis.x-=sin((m.time+1.0/60)*0.6)*0.12/0.48
	axis=axis.limit_length(1)
	return {"analog":{"stick":{"delta":axis.normalized()*(8+30*clampf(axis.length()*10,0,1))}}}
static func polar_input(m: RefCounted, naive: bool=false) -> Dictionary:
	if m.jump_left>0:
		return {}
	var station: int=m.station_at(m.pos) if m.support<0 else -1
	if station>=0 and not m.repaired[station]:
		return {"action":true}
	var next: int=m.repaired.find(false)
	if next<0:
		return {}
	if not naive and m.phase>=2 and fposmod(m.time+1.0/60,5.0)>=2.95:
		return {}
	var goal: Vector2=m.stations[next]
	var best_cost: float=INF
	var best:=Vector2.ZERO
	var origin: Vector2=m.predicted_platform(m.support,1.0/60) if m.support>=0 else m.pos
	var candidates: Array[Vector2]=m.stations.duplicate()
	for index in m.platforms.size():
		candidates.append(m.predicted_platform(index,m.JUMP+1.0/60))
	for candidate: Vector2 in candidates:
		var delta:=candidate-origin
		if delta.length()<30 or delta.length()>0.20*m.W-0.01:
			continue
		var dir:=delta.normalized()
		var target: Vector2=m.target_for(dir,1.0/60)
		if target.distance_to(candidate)>3:
			continue
		var cost: float=target.distance_to(origin) if naive else target.distance_to(goal)
		if not naive and cost>=origin.distance_to(goal)-3:
			continue
		if cost<best_cost:
			best_cost=cost
			best=dir
	if best==Vector2.ZERO:
		return {}
	return {"analog":{"stick":{"delta":best*38}},"pressed":{"fire":Vector2.ZERO}}
