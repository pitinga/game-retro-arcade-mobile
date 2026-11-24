extends RefCounted
# Swept point versus expanded AABB (swept AABB); returns time [0,1], normal,
# or empty on no hit. Initial overlap intentionally delegated to game resolution.
static func sweep_aabb(moving: Rect2, delta: Vector2, target: Rect2) -> Dictionary:
	if moving.size.x <= 0 or moving.size.y <= 0 or target.size.x <= 0 or target.size.y <= 0:
		return {}
	var expanded := Rect2(target.position-moving.size,target.size+moving.size)
	if moving.intersects(target):
		return {"time":0.0,"normal":Vector2.ZERO,"overlap":true}
	var enter: float = -INF
	var exit: float = INF
	var normal := Vector2.ZERO
	for axis: int in [0,1]:
		var velocity: float = delta[axis]
		var origin: float = moving.position[axis]
		var lo: float = expanded.position[axis]
		var hi: float = expanded.end[axis]
		if absf(velocity) < 0.00000001:
			if origin <= lo or origin >= hi:
				return {}
			continue
		var first := (lo-origin)/velocity
		var last := (hi-origin)/velocity
		var near := minf(first,last)
		var far := maxf(first,last)
		if near > enter:
			enter = near
			normal = Vector2.ZERO
			normal[axis] = -signf(velocity)
		exit = minf(exit,far)
		if enter > exit:
			return {}
	if enter < 0.0 or enter > 1.0 or exit < 0.0 or not is_finite(enter):
		return {}
	return {"time":enter,"normal":normal,"overlap":false}

# Segment-circle intersection, t in [0,1] or -1.
static func segment_circle(start: Vector2, delta: Vector2, center: Vector2, radius: float) -> float:
	var relative := start-center
	var c := relative.length_squared()-radius*radius
	if c <= 0:
		return 0.0
	var a := delta.length_squared()
	if a <= 0.000000001:
		return -1.0
	var b := relative.dot(delta)
	var discriminant := b*b-a*c
	if discriminant<0:
		return -1.0
	var t := (-b-sqrt(discriminant))/a
	return t if t>=0 and t<=1 else -1.0

# Swept circle vs rectangle, exact faces and rounded corners.
static func sweep_circle_rect(start: Vector2, delta: Vector2, radius: float, target: Rect2) -> Dictionary:
	var nearest := start.clamp(target.position,target.end)
	if start.distance_squared_to(nearest)<radius*radius-0.000001:
		var n := (start-nearest).normalized()
		if n==Vector2.ZERO:
			n=-delta.normalized() if delta.length_squared()>0 else Vector2.UP
		return {"time":0.0,"normal":n}
	var best: float=2.0
	var normal:=Vector2.ZERO
	for axis: int in [0,1]:
		if absf(delta[axis])<0.00000001:
			continue
		var other:=1-axis
		var direction:=signf(delta[axis])
		var boundary: float=target.position[axis]-radius if direction>0 else target.end[axis]+radius
		var t: float=(boundary-start[axis])/delta[axis]
		if t<0 or t>1 or t>=best:
			continue
		var position: float=start[other]+delta[other]*t
		if position>=target.position[other] and position<=target.end[other]:
			best=t
			normal=Vector2.ZERO
			normal[axis]=-direction
	for corner: Vector2 in [target.position,Vector2(target.end.x,target.position.y),target.end,Vector2(target.position.x,target.end.y)]:
		var t:=segment_circle(start,delta,corner,radius)
		if t<0 or t>=best:
			continue
		var at:=start+delta*t
		var n: Vector2=(at-corner).normalized()
		if n==Vector2.ZERO or delta.dot(n)>=0:
			continue
		if (corner.x==target.position.x and at.x>corner.x) or (corner.x==target.end.x and at.x<corner.x) or (corner.y==target.position.y and at.y>corner.y) or (corner.y==target.end.y and at.y<corner.y):
			continue
		best=t
		normal=n
	return {"time":best,"normal":normal} if best<=1 else {}
