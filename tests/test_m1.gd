extends SceneTree
const Catalog = preload("res://core/catalog.gd")
const Session = preload("res://core/session.gd")
const InputRouter = preload("res://core/input_router.gd")
const Commerce = preload("res://core/commerce.gd")
const Storage = preload("res://core/storage.gd")
const Layout = preload("res://core/layout.gd")
var failures: int = 0
class Fixture extends RefCounted:
	var count: int = 0
	var value: int = 0
	func create(_rng: RandomNumberGenerator,_difficulty: String) -> void:
		count = 0
	func step(input: Dictionary,_dt: float,rng: RandomNumberGenerator) -> Dictionary:
		count += 1
		value += rng.randi_range(0,10) + int(input.get("fire",false))
		return {}
func check(ok: bool, name: String) -> void:
	if not ok:
		failures += 1
		push_error(name)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var free: int = 0
	var ids: Dictionary = {}
	for item: Dictionary in Catalog.ITEMS:
		check(not ids.has(item.id),"R01 unique id")
		ids[item.id] = true
		free += int(item.free)
		check(Catalog.can_access(item.id,false)==item.free,"R01 FREE")
		check(Catalog.can_access(item.id,true),"R01 PRO")
	check(ids.size()==10 and free==3 and not Catalog.can_access("fake",true),"R01 count/access")
	var c := Commerce.new()
	c.begin(0)
	check(c.can_access("G01") and not c.can_access("G04"),"R03 unknown")
	check(not c.show_ad() and c.request_purchase()=="unavailable","R04 no live commerce")
	c.apply_verified_result("purchased",false)
	check(not c.can_access("G04"),"R03 untrusted")
	c.apply_verified_result("free_confirmed",true)
	c.consent = true
	for id: String in ["1","2","3","3"]:
		c.record_completed(id)
	check(not c.eligible("3",179999,true,true),"R02 time")
	check(not c.eligible("3",180000,false,true),"R02 context")
	check(c.reserve_opportunity("3",180000,true,true),"R02 eligible")
	check(not c.reserve_opportunity("3",180000,true,true),"R02 idempotent")
	c.apply_verified_result("purchased",true)
	check(c.can_access("G10") and not c.confirm_impression("3",180000),"R02 PRO race")
	c.apply_verified_result("free_confirmed",true)
	check(c.can_access("G10"),"R03 negative not revoke")
	c.apply_verified_result("revoked_confirmed",true)
	check(not c.can_access("G10"),"R03 confirmed revocation")
	var router := InputRouter.new()
	router.press(0,"left")
	router.press(1,"fire")
	router.release(0)
	check(router.snapshot().has("fire") and not router.snapshot().has("left"),"R08 independent touch")
	router.clear()
	check(router.snapshot().is_empty(),"R08 clear")
	var expected: int = -1
	for fps: int in [30,60,120]:
		var s := Session.new()
		var f := Fixture.new()
		check(s.configure(f,42,"normal") and s.start(),"R07 start")
		for frame in range(fps*3):
			s.set_input({"fire":true})
			s.advance(1.0/float(fps))
		check(s.tick==180,"R07 tick")
		if expected < 0:
			expected = f.value
		check(f.value==expected,"R07 seed replay")
		s.pause()
		check(s.advance(2)==0 and s.tick==180,"R08 paused")
		check(s.resume() and s.advance(5)==5,"R07 clamp")
		check(s.finish({"score":1}) and not s.finish({"score":2}),"R09 result once")
		var result := s.get_result()
		result.score=99
		check(s.get_result().score==1,"R09 result copy")
		s.dispose()
		check(s.advance(1)==0,"R08 dispose")
	var fit := Layout.fit(Rect2(0,0,1080,1920),false)
	check(fit.scale==3 and Layout.logical_point(Vector2(540,960),fit)==Vector2(180,320),"R07 coordinate mapping")
	check(Layout.field(true).size==Vector2(640,248),"R07 field")
	var path := "user://m1-test-"+str(Time.get_ticks_usec())+".json"
	var st := Storage.new(path)
	st.prefs.language="en"
	check(st.save(),"R09 save")
	check(st.record("G01","normal","1",10),"R09 record")
	check(st.record("G01","normal","1",3),"R09 lower score")
	var reloaded := Storage.new(path)
	reloaded.load_data()
	check(reloaded.prefs.language=="en" and reloaded.records.get("G01:normal:1",0)==10,"R09 reload")
	for suffix: String in ["",".tmp",".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	var scene := load("res://app/main.tscn") as PackedScene
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	check(app.page=="catalog","R05 boot")
	app._details("G04")
	check(app.page=="details" and not app.commerce.can_access("G04"),"R01 locked details")
	app._settings()
	check(app.page=="settings","R05 settings")
	app.queue_free()
	await process_frame
	print("M1 failures: ",failures)
	quit(1 if failures else 0)
