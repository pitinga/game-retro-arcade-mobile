extends RefCounted
# Calculate aspect-preserving fit in supplied safe rectangle, in display coordinates.
static func fit(safe: Rect2, landscape: bool) -> Dictionary:
	var logical := Vector2(640,360) if landscape else Vector2(360,640)
	var factor := minf(safe.size.x / logical.x, safe.size.y / logical.y)
	if factor <= 0.0:
		return {"rect": Rect2(), "scale": 0.0}
	var size := logical * factor
	return {"rect": Rect2(safe.position + (safe.size-size)*0.5,size),"scale":factor}
static func field(landscape: bool, g10: bool = false) -> Rect2:
	if landscape:
		return Rect2(0,48,640,312 if g10 else 248)
	return Rect2(0,64,360,464)
static func logical_point(point: Vector2, fitted: Dictionary) -> Variant:
	var rect: Rect2 = fitted.rect
	if fitted.scale <= 0.0 or not rect.has_point(point):
		return null
	return (point-rect.position)/float(fitted.scale)
