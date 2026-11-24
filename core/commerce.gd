extends RefCounted
# No SDK, sales or ads in M1; only adapter policy tested with in-memory fixtures.
enum Entitlement { UNKNOWN, FREE, PRO }
const SALES_ENABLED: bool = false
const ADS_ENABLED: bool = false
var _entitlement: Entitlement = Entitlement.UNKNOWN
var entitlement: Entitlement:
	get:
		return _entitlement
var pending: bool = false
var consent: bool = false
var completed_since_impression: int = 0
var last_impression_ms: int = -1
var started_ms: int = 0
var _seen_results: Dictionary = {}
var _offered: Dictionary = {}

func begin(now_ms: int) -> void:
	started_ms = now_ms
# No grant API is shipped. M7 must implement authenticated receipt verification
# and replace this disabled gate; tests alone exercise policy states.
func can_access(id: String) -> bool:
	return preload("res://core/catalog.gd").can_access(id, SALES_ENABLED and entitlement == Entitlement.PRO)
func record_completed(result_id: String) -> void:
	if result_id.is_empty() or _seen_results.has(result_id):
		return
	_seen_results[result_id] = true
	completed_since_impression += 1
func eligible(result_id: String, now_ms: int, on_result: bool, online: bool) -> bool:
	if entitlement != Entitlement.FREE or pending or not consent or not online or not on_result:
		return false
	if not _seen_results.has(result_id) or _offered.has(result_id) or completed_since_impression < 3:
		return false
	var reference := last_impression_ms if last_impression_ms >= 0 else started_ms
	return now_ms-reference >= 180000
func reserve_opportunity(result_id: String, now_ms: int, on_result: bool, online: bool) -> bool:
	if not eligible(result_id,now_ms,on_result,online):
		return false
	_offered[result_id] = true
	return true
func confirm_impression(result_id: String, now_ms: int) -> bool:
	if entitlement != Entitlement.FREE or pending or not consent or _offered.get(result_id,false) != true:
		return false
	_offered[result_id] = "shown"
	last_impression_ms = now_ms
	completed_since_impression = 0
	return true
func request_purchase() -> String:
	return "unavailable" # no fake checkout in production
func restore() -> String:
	return "unavailable"
func show_ad() -> bool:
	return false # no SDK, no fabricated impression
