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
