extends RefCounted
# Route following reference input generator. Uses actual graph, no score/position injection.
var waypoint: int=-1
var last_round: int=-1
var last_lives: int=-1
func input_for(m: RefCounted) -> Dictionary:
	if m.round!=last_round or m.lives!=last_lives:
		waypoint=-1
		last_round=m.round
		last_lives=m.lives
	var goal: int=-1
	if m.active_count<2:
		var best: int=999
		for i in range(3):
			if m.activated[i]:
				continue
			var route: Array[int]=m.path(m.nearest(m.player),m.ZONES[i])
			if not route.is_empty() and route.size()<best:
				best=route.size()
				goal=m.ZONES[i]
		if goal>=0 and m.player.distance_to(m.node(goal))<10:
			waypoint=-1
			return {"action":true}
	else:
		goal=m.robot_to
		# Chase directly if both occupy one clear horizontal or vertical corridor.
		var delta: Vector2=m.robot-m.player
		if (absf(delta.x)<8 or absf(delta.y)<8) and delta.length()<140:
			var clear: bool=true
			for i in range(1,9):
				if m.blocked(m.player+delta*float(i)/8):
					clear=false
			if clear:
				waypoint=-1
				return {"analog":{"stick":{"delta":delta.normalized()*38}}}
	if waypoint>=0 and m.player.distance_to(m.node(waypoint))<5:
		waypoint=-1
	if waypoint<0:
		var start: int=m.nearest(m.player)
		if m.player.distance_to(m.node(start))>5:
			waypoint=start
		else:
			var route: Array[int]=m.path(start,goal)
			if route.size()>1:
				waypoint=route[1]
			else:
				return {}
	var delta: Vector2=m.node(waypoint)-m.player
	return {"analog":{"stick":{"delta":delta.normalized()*(8+30*clampf(delta.length()/5,0,1))}}}
