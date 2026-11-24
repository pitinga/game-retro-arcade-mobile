extends Control
const Host=preload("res://core/session_host.gd")
const Layout=preload("res://core/layout.gd")
const Session=preload("res://core/session.gd")
const Deep=preload("res://games/cave-rescue/model.gd")
const Emerald=preload("res://games/jungle-expedition/model.gd")
const Skyport=preload("res://games/terminal-chase/model.gd")
const Abyss=preload("res://games/submarine-rescue/model.gd")
const Polar=preload("res://games/ice-platformer/model.gd")
const River=preload("res://games/river-shooter/model.gd")
const Rally=preload("res://games/endurance-racing/model.gd")
const Brick=preload("res://games/brick-breaker/model.gd")
const Orbit=preload("res://games/asteroid-shooter/model.gd")
const Shield=preload("res://games/missile-defense/model.gd")
const ThemeFactory=preload("res://app/arcade_theme.gd")
const BG:=Color("#101522")
const WHITE:=Color("#F5F7FF")
const MINT:=Color("#63E6C4")
const GOLD:=Color("#FFD166")
var game_id: String
var difficulty: String
var language: String="pt"
var left_handed: bool=false
var control_opacity: float=1.0
var model: RefCounted
var host: Node
var pause_button: Button
var overlay: VBoxContainer
var fitted: Dictionary={}
var landscape: bool=false
var _complete: bool=false
var run_seed: int=0
var best_score: int=0
var control_size: float=1.0
var overlay_kind: String=""
signal exit_requested
signal restart_requested
signal completed(result: Dictionary)
func configure(id: String,level: String,locale: String="pt",prefs: Dictionary={},seed_value: int=0) -> void:
	game_id=id
	difficulty=level
	language=locale
	left_handed=bool(prefs.get("left_handed",false))
	control_opacity=clampf(float(prefs.get("control_opacity",100))/100.0,0.5,1.0)
	landscape=id in ["G04","G05","G06","G07","G08","G09","G10"]
	run_seed=seed_value if seed_value!=0 else Time.get_ticks_usec()
	best_score=int(prefs.get("best_score",0))
	control_size=clampf(float(prefs.get("control_size",100))/100.0,0.5,1.5)
func t(pt: String,en: String) -> String:
	return en if language=="en" else pt
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	theme=ThemeFactory.build()
	match game_id:
		"G01": model=River.new()
		"G02": model=Rally.new()
		"G03": model=Brick.new()
		"G04": model=Abyss.new()
		"G05": model=Polar.new()
		"G06": model=Deep.new()
		"G08": model=Emerald.new()
		"G07": model=Skyport.new()
		"G09": model=Orbit.new()
		"G10": model=Shield.new()
		_: return
	host=Host.new()
	add_child(host)
	host.configure(model,run_seed,difficulty)
	host.paused.connect(_on_paused)
	host.finished.connect(_on_result)
	pause_button=Button.new()
	pause_button.text="II"
	pause_button.tooltip_text=t("Pausa","Pause")
	pause_button.pressed.connect(pause_game)
	add_child(pause_button)
	resized.connect(_layout)
	_layout()
	host.start()
	_show_intro()
func _layout() -> void:
	if not is_instance_valid(host):
		return
	var safe:=Rect2(Vector2.ZERO,size)
	if OS.has_feature("android"):
		var a:=DisplayServer.get_display_safe_area()
		var screen:=DisplayServer.screen_get_size()
		if screen.x>0 and screen.y>0 and a.size.x>0 and a.size.y>0:
			var factor:=size/Vector2(screen)
			safe=Rect2(Vector2(a.position)*factor,Vector2(a.size)*factor).intersection(safe)
	fitted=Layout.fit(safe,landscape)
	var controls: Dictionary={}
	match game_id:
		"G01":
			controls={"paddle":Rect2(0,64,360,464),"fire":Rect2(0,528,180,112),"up":Rect2(180,528,180,56),"down":Rect2(180,584,180,56)}
		"G02":
			controls={"paddle":Rect2(0,64,360,464),"up":Rect2(0,528,180,56),"down":Rect2(180,528,180,56),"left":Rect2(0,584,100,56),"right":Rect2(100,584,100,56),"secondary":Rect2(200,584,160,56)}
		"G03":
			controls={"paddle":Rect2(0,64,360,520),"fire":Rect2(0,584,360,56)}
		"G04":
			controls={"stick":Rect2(0,296,280,64),"fire":Rect2(400,296,240,64)}
			if left_handed:
				controls={"stick":Rect2(360,296,280,64),"fire":Rect2(0,296,240,64)}
		"G05":
			controls={"stick":Rect2(0,296,256,64),"fire":Rect2(368,296,136,64),"action":Rect2(504,296,136,64)}
			if left_handed:
				controls={"stick":Rect2(384,296,256,64),"fire":Rect2(0,296,136,64),"action":Rect2(136,296,136,64)}
		"G06":
			controls={"left":Rect2(0,296,96,64),"right":Rect2(96,296,96,64),"fire":Rect2(304,296,112,64),"action":Rect2(416,296,112,64),"secondary":Rect2(528,296,112,64)}
			if left_handed:
				controls={"left":Rect2(448,296,96,64),"right":Rect2(544,296,96,64),"fire":Rect2(0,296,112,64),"action":Rect2(112,296,112,64),"secondary":Rect2(224,296,112,64)}
		"G08":
			controls={"stick":Rect2(0,296,280,64),"fire":Rect2(360,296,140,64),"action":Rect2(500,296,140,64)}
			if left_handed:
				controls={"stick":Rect2(360,296,280,64),"fire":Rect2(0,296,140,64),"action":Rect2(140,296,140,64)}
		"G07":
			controls={"stick":Rect2(0,296,280,64),"action":Rect2(360,296,140,64),"secondary":Rect2(500,296,140,64)}
			if left_handed:
				controls={"stick":Rect2(360,296,280,64),"action":Rect2(0,296,140,64),"secondary":Rect2(140,296,140,64)}
		"G09":
			if left_handed:
				controls={"left":Rect2(392,296,62,64),"right":Rect2(454,296,62,64),"up":Rect2(516,296,124,64),"fire":Rect2(0,296,120,64),"secondary":Rect2(120,296,120,64)}
			else:
				controls={"left":Rect2(0,296,62,64),"right":Rect2(62,296,62,64),"up":Rect2(124,296,124,64),"fire":Rect2(392,296,120,64),"secondary":Rect2(512,296,128,64)}
		"G10":
			controls={"aim":Rect2(0,48,640,278)}
	# Size preference adjusts button height inside reserved bands, never below 48u.
	for action: String in controls:
		if action in ["aim","paddle","stick"]:
			continue
		var area: Rect2=controls[action]
		var target_size:=Vector2(clampf(area.size.x*control_size/1.5,48.0,area.size.x),clampf(area.size.y*control_size/1.5,48.0,area.size.y))
		controls[action]=Rect2(area.get_center()-target_size/2,target_size)
	host.configure_layout(safe,landscape,controls)
	var rect: Rect2=fitted.rect
	var scale: float=fitted.scale
	var logical_w: float=640 if landscape else 360
	pause_button.position=rect.position+Vector2(logical_w-64,8)*scale
	pause_button.size=Vector2(56,48)*scale
	host.excluded_touch=Rect2(logical_w-64,8,56,48)
	if is_instance_valid(overlay):
		_place_overlay()
	queue_redraw()
func _place_overlay() -> void:
	var rect: Rect2=fitted.get("rect",Rect2(Vector2.ZERO,size))
	var width:=minf(rect.size.x*0.88,380)
	overlay.position=rect.position+Vector2((rect.size.x-width)/2,maxf(10,(rect.size.y-overlay.get_combined_minimum_size().y)/2))
	overlay.size=Vector2(width,0)
func _clear_overlay() -> void:
	if is_instance_valid(overlay):
		remove_child(overlay)
		overlay.queue_free()
		overlay=null
func _overlay(title: String,actions: Array) -> void:
	_clear_overlay()
	overlay=VBoxContainer.new()
	overlay.add_theme_constant_override("separation",8)
	add_child(overlay)
	var header:=Label.new()
	header.text=title
	header.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	header.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	header.add_theme_font_size_override("font_size",18)
	overlay.add_child(header)
	for item: Array in actions:
		var button:=Button.new()
		button.text=item[0]
		button.custom_minimum_size.y=52
		button.pressed.connect(item[1])
		overlay.add_child(button)
	_place_overlay()
	queue_redraw()
func _show_intro() -> void:
	host.pause_game()
	overlay_kind="intro"
	var message:=t("Arraste a raquete. Toque SERVIR.","Drag the paddle. Tap SERVE.")
	if game_id=="G01":
		message=t("Arraste para pilotar. Colete energia e dispare.","Drag to steer. Collect energy and fire.")
	elif game_id=="G02":
		message=t("Acelere, desvie e alcance a meta do dia. AUTO alterna aceleração.","Accelerate, steer and meet the daily goal. AUTO toggles acceleration.")
	elif game_id=="G04":
		message=t("Resgate cápsulas e pare na superfície para entregar e recarregar O2.","Rescue pods and stop at the surface to deliver and refill O2.")
	elif game_id=="G05":
		message=t("Escolha a direção, SALTE e segure REPARAR em três estações.","Choose direction, JUMP and hold REPAIR at three stations.")
	elif game_id=="G06":
		message=t("Voe com JET, use PULSO e CORTE. Afaste-se da carga e pare perto do cientista para resgatar.","Hold JET, use PULSE and CUT. Move away from the charge, stop near the scientist to rescue.")
	elif game_id=="G08":
		message=t("Explore, salte e use a direção vertical para escalar. Reúna quatro artefatos e volte ao acampamento.","Explore, jump and use vertical direction to climb. Collect four artifacts and return to camp.")
	elif game_id=="G07":
		message=t("Ative dois bloqueadores e intercepte o robô antes da fuga.","Activate two blockers, then intercept the robot before escape.")
	elif game_id=="G09":
		message=t("Gire, acelere, dispare e use DASH.","Rotate, thrust, shoot and DASH.")
	elif game_id=="G10":
		message=t("Toque no campo para interceptar os detritos.","Tap the field to intercept debris.")
	_overlay(message,[[t("Jogar","Play"),_resume],[t("Catálogo","Catalogue"),func(): exit_requested.emit()]])
func pause_game() -> void:
	if is_instance_valid(host):
		host.pause_game()
func _on_paused() -> void:
	overlay_kind="pause"
	_overlay(t("PAUSA","PAUSED"),[[t("Continuar","Resume"),_resume],[t("Reiniciar","Restart"),_confirm_restart],[t("Catálogo","Catalogue"),_confirm_exit]])
func _resume() -> void:
	overlay_kind=""
	_clear_overlay()
	host.resume_game()
func _confirm_restart() -> void:
	overlay_kind="confirm"
	_overlay(t("Reiniciar a partida?","Restart game?"),[[t("Confirmar","Confirm"),func(): restart_requested.emit()],[t("Cancelar","Cancel"),_on_paused]])
func _confirm_exit() -> void:
	overlay_kind="confirm"
	_overlay(t("Abandonar a partida?","Leave game?"),[[t("Confirmar","Confirm"),func(): exit_requested.emit()],[t("Cancelar","Cancel"),_on_paused]])
func back() -> void:
	if _complete:
		exit_requested.emit()
	elif overlay_kind=="confirm":
		_on_paused()
	elif overlay_kind in ["intro","pause"]:
		_confirm_exit()
	else:
		pause_game()
func _on_result(result: Dictionary) -> void:
	if _complete:
		return
	_complete=true
	pause_button.disabled=true
	result["seed"]=run_seed
	best_score=maxi(best_score,int(result.get("score",0)))
	completed.emit(result)
	overlay_kind="result"
	var reason:=t("Derrota","Defeat") if result.get("reason","lost")=="lost" else str(result.get("reason",""))
	_overlay(t("FIM DE JOGO","GAME OVER")+"\n"+reason+" · "+t("Pontos: ","Score: ")+str(result.get("score",0))+"\n"+t("Recorde: ","Best: ")+str(best_score)+"\nSeed: "+str(run_seed),[[t("Repetir","Play again"),func(): restart_requested.emit()],[t("Catálogo","Catalogue"),func(): exit_requested.emit()]])
func _process(_delta: float) -> void:
	queue_redraw()
func _txt(pos: Vector2,value: String,sz: int=16,color: Color=WHITE) -> void:
	draw_string(ThemeDB.fallback_font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),BG)
	if not is_instance_valid(host) or fitted.is_empty() or fitted.scale<=0:
		return
	var rect: Rect2=fitted.rect
	draw_set_transform(rect.position,0,Vector2.ONE*float(fitted.scale))
	var w: float=640 if landscape else 360
	var h: float=360 if landscape else 640
	draw_rect(Rect2(0,0,w,h),BG)
	if game_id=="G01":
		_draw_river()
	elif game_id=="G02":
		_draw_rally()
	elif game_id=="G03":
		_draw_brick()
	elif game_id=="G04":
		_draw_abyss()
	elif game_id=="G05":
		_draw_polar()
	elif game_id=="G06":
		_draw_deep()
	elif game_id=="G08":
		_draw_emerald()
	elif game_id=="G07":
		_draw_skyport()
	elif game_id=="G09":
		_draw_orbit()
	elif game_id=="G10":
		_draw_shield()
	draw_set_transform(Vector2.ZERO)
	if is_instance_valid(overlay):
		draw_rect(rect,Color(0.02,0.03,0.06,0.85))
func _control(rect: Rect2,label: String) -> void:
	draw_rect(rect.grow(-3),Color(0.125,0.165,0.235,control_opacity))
	draw_rect(rect.grow(-3),Color(0.51,0.58,0.69,control_opacity),false,2)
	_txt(rect.position+Vector2(12,rect.size.y/2+5),label,14)
func _draw_brick() -> void:
	_txt(Vector2(12,23),"PRISM BREAK",18,MINT)
	_txt(Vector2(12,46),"%06d  F%02d  %s %d"%[model.score,model.phase,t("VIDAS","LIVES"),model.lives],14)
	draw_rect(Rect2(0,64,360,464),Color("#151B35"))
	var shift:=Vector2(0,64)
	for block: Dictionary in model.blocks:
		var box: Rect2=block.rect
		box.position+=shift
		var color: Color=[Color("#A78BFA"),Color("#4BD9C6"),Color("#FFC878")][block.initial-1]
		draw_rect(box,color)
		draw_rect(box,Color("#F5F7FF"),false,1)
		for index in int(block.hp):
			draw_rect(Rect2(box.position+Vector2(4+index*8,7),Vector2(5,6)),Color("#151B35"))
	var p: Rect2=model.paddle_rect()
	p.position+=shift
	draw_rect(p,WHITE)
	draw_rect(Rect2(p.position+Vector2(4,2),Vector2(p.size.x-8,2)),MINT)
	draw_circle(Vector2(model.ball)+shift,Brick.R,WHITE)
	for drop: Dictionary in model.drops:
		draw_circle(Vector2(drop.pos)+shift,7,GOLD)
		_txt(Vector2(drop.pos)+shift+Vector2(-4,4),"+" if drop.kind==0 else "S",12,BG)
	_control(Rect2(0,528,360,56),t("<  ARRASTE  >","<  DRAG  >"))
	_control(host.touch_regions["fire"],t("SERVIR","SERVE"))
	if model.serving:
		_txt(Vector2(112,330),t("PRONTO?","READY?"),22,MINT)
func _draw_orbit() -> void:
	_txt(Vector2(12,19),"ORBIT SHARDS",17,MINT)
	_txt(Vector2(12,39),"%06d  %s %d   %s %d   DASH %.1f"%[model.score,t("ONDA","WAVE"),model.wave,t("VIDAS","LIVES"),model.lives,model.dash_cd],14)
	draw_rect(Rect2(0,48,640,248),Color("#11152D"))
	for idx in range(35):
		var star:=Vector2(float((idx*107+31)%640),float((idx*53+17)%248)+48)
		draw_circle(star,1,Color("#30365D"))
	for rock: Dictionary in model.rocks:
		var r: float=model.radius(rock.size)
		var c: Color=Color("#FF987A") if rock.size==3 else Color("#C4A4FF")
		for dx: float in [-640.0,0.0,640.0]:
			for dy: float in [-248.0,0.0,248.0]:
				var point:=Vector2(rock.pos)+Vector2(dx,dy)
				if Rect2(-r,-r,640+2*r,248+2*r).has_point(point):
					_polygon_rock(point+Vector2(0,48),r,c,int(rock.id))
	for shot: Dictionary in model.shots:
		draw_circle(Vector2(shot.pos)+Vector2(0,48),2,WHITE)
	if model.respawn<0:
		var forward:=Vector2.from_angle(model.angle)
		var right:=forward.orthogonal()
		for dx: float in [-640.0,0.0,640.0]:
			for dy: float in [-248.0,0.0,248.0]:
				var point:=Vector2(model.ship)+Vector2(dx,dy)
				if Rect2(-13,-13,666,274).has_point(point):
					point+=Vector2(0,48)
					draw_colored_polygon(PackedVector2Array([point+forward*13,point-forward*8+right*8,point-forward*4,point-forward*8-right*8]),MINT)
					if model.immune>0:
						draw_arc(point,16,0,TAU,24,WHITE,1)
	# Mask any wrapped copies crossing the field boundary, then repaint HUD.
	draw_rect(Rect2(0,0,640,48),BG)
	draw_rect(Rect2(0,296,640,64),BG)
	_txt(Vector2(12,19),"ORBIT SHARDS",17,MINT)
	_txt(Vector2(12,39),"%06d  %s %d   %s %d   DASH %.1f"%[model.score,t("ONDA","WAVE"),model.wave,t("VIDAS","LIVES"),model.lives,model.dash_cd],14)
	for key: String in host.touch_regions:
		var label: String={"left":"<","right":">","up":t("PROPULSÃO","THRUST"),"fire":t("TIRO","FIRE"),"secondary":"DASH"}[key]
		_control(host.touch_regions[key],label)
	if model.wave_wait>=0:
		_txt(Vector2(245,175),t("PRÓXIMA ONDA","NEXT WAVE"),20,GOLD)
func _polygon_rock(point: Vector2,r: float,c: Color,id: int) -> void:
	var verts:=PackedVector2Array()
	for i in range(6):
		var scale:=0.78+float((id+i*7)%5)*0.05
		verts.append(point+Vector2.from_angle(float(i)*TAU/6)*r*scale)
	draw_colored_polygon(verts,c)
	draw_line(point,verts[1],Color("#30365D"),2)
	draw_line(point,verts[3],Color("#30365D"),2)
func _draw_shield() -> void:
	_txt(Vector2(12,19),"AURORA SHIELD",17,MINT)
	_txt(Vector2(12,39),"%06d  %s %d  %s %d/5  A:%d B:%d"%[model.score,t("ONDA","WAVE"),model.wave,t("BASES","BASES"),model.habitats.count(true),model.ammo[0],model.ammo[1]],14)
	draw_rect(Rect2(0,48,640,312),Color("#18243D"))
	var shift:=Vector2(0,48)
	draw_colored_polygon(PackedVector2Array([Vector2(0,120),Vector2(100,90),Vector2(260,120),Vector2(430,65),Vector2(640,88),Vector2(640,110),Vector2(430,88),Vector2(260,145),Vector2(100,110),Vector2(0,140)]),Color("#204D53"))
	draw_rect(Rect2(0,348,640,12),Color("#52707C"))
	for i in range(7):
		var p: Vector2=model.positions[i]+shift
		var alive: bool=model.target_alive(i)
		var c:=Color("#E7C77D") if i<2 else Color("#BDDEEA")
		draw_rect(Rect2(p-Vector2(15,18),Vector2(30,18)),c if alive else Color("#465467"))
		if alive:
			draw_rect(Rect2(p-Vector2(5,12),Vector2(10,7)),Color("#18243D"))
		else:
			draw_line(p-Vector2(10,17),p+Vector2(10,-1),WHITE,2)
			draw_line(p+Vector2(10,-17),p-Vector2(10,1),WHITE,2)
	for threat: Dictionary in model.threats:
		var p:=Vector2(threat.pos)+shift
		draw_line(Vector2(threat.start)+shift,p,Color("#C28E9E"),2)
		draw_circle(p,4 if threat.fragment else 3,Color("#FF9B72"))
		if threat.fragment:
			draw_arc(p,7,0,TAU,12,GOLD,1)
	for shot: Dictionary in model.shots:
		draw_circle(Vector2(shot.pos)+shift,3,WHITE)
	for bubble: Dictionary in model.bubbles:
		var p:=Vector2(bubble.pos)+shift
		var r: float=model.bubble_radius(bubble.age)
		if r>0:
			draw_circle(p,r,Color(0.44,0.84,1,0.24))
			draw_arc(p,r,0,TAU,32,Color("#70D6FF"),2)
	var aim:=Vector2(model.cursor)+shift
	draw_line(aim-Vector2(6,0),aim+Vector2(6,0),MINT,1)
	draw_line(aim-Vector2(0,6),aim+Vector2(0,6),MINT,1)
	if model.wave_wait>=0:
		_txt(Vector2(245,175),t("PRÓXIMA ONDA","NEXT WAVE"),20,GOLD)

func _draw_river() -> void:
	_txt(Vector2(12,23),"CANYON WINGS",18,MINT)
	_txt(Vector2(12,46),"%06d  S%02d  %s %d"%[model.score,model.sector,t("VIDAS","LIVES"),model.lives],14)
	draw_rect(Rect2(0,64,360,464),Color("#BF946A"))
	var left:=PackedVector2Array([Vector2(0,64)])
	var right:=PackedVector2Array([Vector2(360,64)])
	for sy in range(0,465,8):
		var lane: Vector2=model.corridor(model.distance+River.Y-float(sy))
		left.append(Vector2(lane.x-lane.y/2,64+sy))
		right.append(Vector2(lane.x+lane.y/2,64+sy))
	left.append(Vector2(0,528))
	right.append(Vector2(360,528))
	draw_rect(Rect2(0,64,360,464),Color("#184C79"))
	draw_colored_polygon(left,Color("#E2B48B"))
	draw_colored_polygon(right,Color("#E2B48B"))
	for i in range(1,left.size()-2):
		draw_line(left[i],left[i+1],Color("#76523D"),2)
		draw_line(right[i],right[i+1],Color("#76523D"),2)
	for item: Dictionary in model.objects:
		if model.consumed.has(item.id):
			continue
		var sy: float=model.screen_y(item.z)
		if sy<14 or sy>450:
			continue
		var p:=Vector2(item.get("draw_x",item.x),sy+64)
		if item.kind=="energy":
			draw_rect(Rect2(p-Vector2(10,11),Vector2(20,22)),MINT)
			draw_rect(Rect2(p-Vector2(10,11),Vector2(20,22)),WHITE,false,2)
			_txt(p+Vector2(-5,5),"+",16,BG)
		elif item.kind=="beacon":
			draw_colored_polygon(PackedVector2Array([p+Vector2(0,-12),p+Vector2(10,0),p+Vector2(0,12),p+Vector2(-10,0)]),GOLD)
		else:
			draw_colored_polygon(PackedVector2Array([p+Vector2(-12,-8),p+Vector2(12,-8),p+Vector2(7,9),p+Vector2(-7,9)]),Color("#F9A69E"))
			draw_rect(Rect2(p-Vector2(4,3),Vector2(8,6)),BG)
	for shot: Dictionary in model.shots:
		var p: Vector2=shot.pos+Vector2(0,64)
		draw_line(p,p+Vector2(0,8),WHITE,2)
	for shot: Dictionary in model.hostile:
		draw_circle(Vector2(shot.pos)+Vector2(0,64),4,Color("#FF9B72"))
	var plane:=Vector2(model.x,River.Y+64)
	draw_colored_polygon(PackedVector2Array([plane+Vector2(0,-15),plane+Vector2(15,10),plane+Vector2(0,5),plane+Vector2(-15,10)]),WHITE)
	draw_line(plane+Vector2(0,-8),plane+Vector2(0,7),MINT,3)
	if model.immune>0:
		draw_arc(plane,19,0,TAU,24,MINT,2)
	draw_rect(Rect2(12,70,112,14),BG)
	draw_rect(Rect2(14,72,108*float(model.energy)/100,10),GOLD if model.energy<=25 else MINT)
	_txt(Vector2(130,83),t("ENERGIA ","ENERGY ")+str(int(model.energy))+"%",13)
	for key: String in host.touch_regions:
		if key!="paddle":
			var label: String={"fire":t("TIRO","FIRE"),"up":t("ACELERAR","BOOST"),"down":t("FREAR","BRAKE")}[key]
			_control(host.touch_regions[key],label)
func road_point(z: float,lateral: float) -> Vector2:
	var depth:=clampf(1.0-z/150.0,0,1)
	var half:=lerpf(15,172,depth)
	var center:=180+float(model.curve(model.distance+z))*120*depth
	return Vector2(center+lateral*half,64+130+depth*315)
func _draw_rally() -> void:
	_txt(Vector2(12,22),"HORIZON RALLY",18,MINT)
	_txt(Vector2(12,45),"D%02d  %02d/%02d  %03d km/h"%[model.day,model.passes,model.goal,int(model.speed*3.6)],14)
	var sky: Color=[Color("#5FA9C7"),Color("#BC7774"),Color("#202A49"),Color("#C5A08C")][model.phase()]
	var land: Color=Color("#0B1711") if model.phase()!=2 else Color("#081210")
	draw_rect(Rect2(0,64,360,130),sky)
	draw_rect(Rect2(0,194,360,334),land)
	for i in range(30):
		var far_z:=150-float(i)*5
		var near_z:=far_z-5
		var quad:=PackedVector2Array([road_point(far_z,-1),road_point(far_z,1),road_point(near_z,1),road_point(near_z,-1)])
		draw_colored_polygon(quad,Color("#66758C") if i%2==0 else Color("#728098"))
		for line: float in [-1.0,1.0]:
			draw_line(road_point(far_z,line),road_point(near_z,line),WHITE,2)
		if int((model.distance+near_z)/8)%2==0:
			for line: float in [-0.33,0.33]:
				draw_line(road_point(far_z,line),road_point(near_z,line),Color("#B5C3D8"),1)
	var ordered: Array=model.rivals.duplicate()
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.z>b.z)
	for car: Dictionary in ordered:
		if car.z<0 or car.z>150:
			continue
		var p:=road_point(car.z,model.car_lateral(car))
		var depth:=clampf(1-float(car.z)/150,0,1)
		var r:=Vector2(lerpf(7,26,depth),lerpf(5,24,depth))
		draw_rect(Rect2(p-r/2,r),Color("#FFE4B2"))
		draw_rect(Rect2(p-r/2,r),BG,false,2)
		if float(car.get("warn",0))>0:
			var arrow:=p+Vector2(signf(float(car.target-car.lane))*maxf(r.x/2,7),-r.y/2)
			draw_circle(arrow,7,BG)
			_txt(arrow+Vector2(-4,4),">" if car.target>car.lane else "<",12,WHITE)
		draw_rect(Rect2(p-r/2+Vector2(2,r.y-4),Vector2(3,3)),Color("#FF4E70"))
		draw_rect(Rect2(p+r/2-Vector2(5,4),Vector2(3,3)),Color("#FF4E70"))
	var player:=road_point(0,model.lateral)
	draw_rect(Rect2(player-Vector2(20,13),Vector2(40,26)),MINT)
	draw_rect(Rect2(player-Vector2(20,13),Vector2(40,26)),WHITE,false,2)
	draw_rect(Rect2(player-Vector2(12,10),Vector2(24,9)),BG)
	draw_rect(Rect2(8,70,214,48),BG)
	_txt(Vector2(14,88),"%s %02ds  HP %d"%[t("TEMPO","TIME"),int(ceil(90-model.elapsed)),model.integrity],14)
	_txt(Vector2(14,108),t("DESVIE DO TRÁFEGO","AVOID TRAFFIC"),13,GOLD)
	if model.elapsed>=model.weather_start-3 and model.elapsed<model.weather_start:
		_txt(Vector2(230,88),t("NEBLINA LOGO","FOG SOON"),14,GOLD)
	elif model.elapsed>=model.weather_start+7 and model.elapsed<model.weather_start+10:
		_txt(Vector2(230,88),t("GELO LOGO","ICE SOON"),14,GOLD)
	if model.fog:
		draw_rect(Rect2(0,194,360,315),Color(0.75,0.85,0.9,0.19))
		_txt(Vector2(230,88),t("NEBLINA","FOG"),14,GOLD)
	elif model.ice:
		_txt(Vector2(230,88),t("GELO","ICE"),14,GOLD)
	if model.countdown>0:
		_txt(Vector2(164,300),str(int(ceil(model.countdown))),32,WHITE)
	for key: String in host.touch_regions:
		if key!="paddle":
			var label: String={"up":t("ACELERAR","ACCEL"),"down":t("FREAR","BRAKE"),"left":"<","right":">","secondary":"AUTO "+("ON" if model.auto_accel else "OFF")}[key]
			_control(host.touch_regions[key],label)

func _draw_abyss() -> void:
	_txt(Vector2(12,19),"ABYSS RESCUE",17,MINT)
	_txt(Vector2(12,39),"%06d  O2 %d%%  %s %d  %s %d/%d  %s %d"%[model.score,int(model.oxygen),t("VIDAS","LIVES"),model.lives,t("CARGA","CARGO"),model.cargo,model.capacity(),t("ONDA","WAVE"),model.wave],14)
	draw_rect(Rect2(0,48,640,248),Color("#163E59"))
	draw_rect(Rect2(0,48,640,0.10*Abyss.H),Color("#D5F4F5"))
	draw_rect(Rect2(0,48+0.95*Abyss.H,640,0.05*Abyss.H),Color("#D5AA78"))
	for i in range(15):
		var x: float=float((i*113+50)%640)
		draw_line(Vector2(x,292),Vector2(x+8,276-float(i%3)*4),Color("#64A6A0"),3)
	var shift:=Vector2(0,48)
	for c: Dictionary in model.capsules:
		var p: Vector2=c.pos+shift
		draw_circle(p,10,Color("#F8C36A"))
		draw_arc(p,10,0,TAU,20,WHITE,2)
		draw_rect(Rect2(p-Vector2(4,4),Vector2(8,8)),BG)
	for e: Dictionary in model.enemies:
		var p: Vector2=e.pos+shift
		draw_colored_polygon(PackedVector2Array([p+Vector2(-13,0),p+Vector2(0,-9),p+Vector2(13,0),p+Vector2(0,9)]),Color("#F28D9B"))
		draw_circle(p,3,BG)
	for shot: Dictionary in model.shots:
		var p: Vector2=shot.pos+shift
		draw_line(p,p+Vector2(-8*signf(shot.vx),0),WHITE,3)
	var p: Vector2=model.pos+shift
	draw_rect(Rect2(p-Vector2(17,8),Vector2(34,16)),MINT)
	draw_rect(Rect2(p+Vector2(-5,-14),Vector2(10,6)),MINT)
	draw_circle(p+Vector2(model.direction*8,0),5,BG)
	if model.immune>0:
		draw_arc(p,21,0,TAU,24,WHITE,1)
	if model.wave_wait>0:
		_txt(Vector2(245,180),t("NOVA ONDA","NEXT WAVE"),22,GOLD)
	for key: String in host.touch_regions:
		_control(host.touch_regions[key],t("DIREÇÃO","STEER") if key=="stick" else t("PULSO","PULSE"))
func _draw_polar() -> void:
	_txt(Vector2(12,19),"POLAR WORKSHOP",17,MINT)
	_txt(Vector2(12,39),"%06d  %s %d%%  %s %d/3  F%d  %s %d"%[model.score,t("ENERGIA","ENERGY"),int(model.energy),t("EST","STN"),model.repaired.count(true),model.phase,t("VIDAS","LIVES"),model.lives],14)
	draw_rect(Rect2(0,48,640,248),Color("#203E6E"))
	var shift:=Vector2(0,48)
	for station: Vector2 in model.stations:
		var points:=PackedVector2Array()
		for i in range(49):
			var angle:=float(i)*TAU/48
			points.append(station+shift+Vector2(cos(angle)*83,sin(angle)*56))
		draw_polyline(points,Color("#8295B0"),1)
	for platform: Dictionary in model.platforms:
		var p: Vector2=platform.pos+shift
		draw_rect(Rect2(p-Vector2(22,13),Vector2(44,26)),Color("#E3F1F5"))
		draw_rect(Rect2(p-Vector2(22,13),Vector2(44,26)),Color("#15243D"),false,2)
	for i in range(3):
		var p: Vector2=model.stations[i]+shift
		draw_circle(p,31,Color("#E3F1F5"))
		draw_arc(p,31,0,TAU,32,Color("#15243D"),3)
		draw_rect(Rect2(p-Vector2(15,14),Vector2(30,28)),Color("#15243D"))
		if model.repaired[i]:
			draw_line(p+Vector2(-9,0),p+Vector2(-3,7),MINT,3)
			draw_line(p+Vector2(-3,7),p+Vector2(10,-8),MINT,3)
		else:
			_txt(p+Vector2(-4,6),"!",18,GOLD)
		_txt(p+Vector2(-26,45),str(i+1)+" "+(t("OK","OK") if model.repaired[i] else t("PEND","WAIT")),12,WHITE)
		if model.repair_index==i:
			draw_arc(p,35,-PI/2,-PI/2+TAU*model.repair_time,24,MINT,3)
	for drone: Dictionary in model.drones:
		var p: Vector2=drone.pos+shift
		draw_circle(p,9,Color("#FF9B72"))
		draw_arc(p,10,0,TAU,16,WHITE,2)
	_txt(Vector2(12,69),"%02ds"%int(ceil(model.remaining)),16,WHITE)
	if model.gust or model.gust_warning:
		_txt(Vector2(220,69),t("RAJADA: AGUARDE","GUST: WAIT") if model.gust else t("RAJADA EM BREVE","GUST SOON"),16,GOLD)
	var p: Vector2=model.pos+shift
	if model.jump_left<=0:
		var target: Vector2=model.target_in_direction()+shift
		draw_line(p,target,WHITE,1)
		draw_arc(target,7,0,TAU,16,GOLD,2)
	draw_circle(p,10,Color("#15243D"))
	draw_arc(p,10,0,TAU,20,WHITE,2)
	draw_rect(Rect2(p-Vector2(4,6),Vector2(8,8)),MINT)
	for key: String in host.touch_regions:
		var label: String={"stick":t("DIREÇÃO","STEER"),"fire":t("SALTO","JUMP"),"action":t("REPARAR","REPAIR")}[key]
		_control(host.touch_regions[key],label)

func _draw_skyport() -> void:
	_txt(Vector2(12,19),"SKYPORT CHASE",17,MINT)
	_txt(Vector2(12,39),"%06d  %s %02ds  %s %d  R%d  %s %d/2  DASH %.1f"%[model.score,t("TEMPO","TIME"),int(ceil(model.remaining)),t("VIDAS","LIVES"),model.lives,model.round,t("BLOQ","LOCK"),model.active_count,model.dash_cd],14)
	var shift:=Vector2(0,48)
	draw_rect(Rect2(0,48,640,248),Color("#344A61"))
	for wall: Rect2 in model.walls:
		var box:=Rect2(wall.position+shift,wall.size)
		draw_rect(box,Color("#17243B"))
		draw_rect(box,Color("#A9BBD3"),false,2)
		draw_line(box.position+Vector2(5,7),box.position+Vector2(box.size.x-5,7),Color("#506680"),2)
	for area: Rect2 in model.maintenance:
		var box:=Rect2(area.position+shift,area.size)
		draw_rect(box,Color("#634A36"))
		for i in range(0,int(area.size.x),14):
			draw_line(box.position+Vector2(i,3),box.position+Vector2(i,box.size.y-3),GOLD,2)
		draw_rect(box,GOLD,false,2)
	var conveyor:=Rect2(65,151,130,42)
	draw_rect(conveyor,Color("#294C50"))
	if model.conveyor_warning:
		draw_rect(conveyor,GOLD,false,3)
	for i in range(5):
		_txt(conveyor.position+Vector2(8+i*24,26),">" if fposmod(model.time,8)<4 else "<",18,MINT)
	var door: Rect2=model.door_rect()
	door.position+=shift
	draw_rect(door,GOLD if model.door_warning else (Color("#F08A99") if model.door_closed else MINT),model.door_closed,2)
	var door_center:=door.get_center()
	if model.door_warning:
		draw_rect(Rect2(door_center-Vector2(10,10),Vector2(20,20)),BG)
		_txt(door_center+Vector2(-4,6),"!",18,GOLD)
	elif model.door_closed:
		draw_line(door.position,door.end,WHITE,2)
		draw_line(Vector2(door.end.x,door.position.y),Vector2(door.position.x,door.end.y),WHITE,2)
	for i in range(3):
		var p: Vector2=model.node(model.ZONES[i])+shift
		draw_circle(p,22,BG)
		draw_arc(p,22,0,TAU,24,MINT if model.activated[i] else GOLD,3)
		_txt(p+Vector2(-13,4),"OK" if model.activated[i] else "B"+str(i+1),13,WHITE)
		if model.progress_zone==i:
			draw_arc(p,25,-PI/2,-PI/2+TAU*model.progress/0.6,24,MINT,3)
	for id: int in model.EXITS:
		var p: Vector2=model.node(id)+shift
		var open: bool=id==model.exit_id and model.remaining<=10
		var warn: bool=id==model.exit_id and model.exit_revealed
		draw_rect(Rect2(p-Vector2(18,12),Vector2(36,24)),BG)
		draw_rect(Rect2(p-Vector2(18,12),Vector2(36,24)),GOLD if warn else WHITE,false,2)
		_txt(p+Vector2(-12,4),"OUT" if open else ("!" if warn else "X"),12,WHITE)
	for d: Dictionary in model.drones:
		var p: Vector2=d.pos+shift
		draw_colored_polygon(PackedVector2Array([p+Vector2(-9,0),p+Vector2(0,-10),p+Vector2(9,0),p+Vector2(0,10)]),Color("#FF9B72"))
		draw_arc(p,13,0,TAU,20,GOLD,1)
	var target: Vector2=model.robot+shift
	draw_rect(Rect2(target-Vector2(13,11),Vector2(26,22)),Color("#C4A4FF"))
	draw_rect(Rect2(target-Vector2(13,11),Vector2(26,22)),WHITE,false,2)
	draw_rect(Rect2(target-Vector2(6,4),Vector2(12,8)),BG)
	var p: Vector2=model.player+shift
	if model.stun>0:
		draw_arc(p,15,0,TAU,20,GOLD,3)
	draw_circle(p,11,BG)
	draw_arc(p,11,0,TAU,24,MINT,3)
	draw_line(p,p+Vector2(model.last_axis)*12,WHITE,2)
	if model.door_warning or model.conveyor_warning:
		_txt(Vector2(10,68),t("ATENÇÃO: MUDANÇA","CAUTION: CHANGE"),13,GOLD)
	if model.contact_hint>0:
		_txt(Vector2(200,70),t("ATIVE DOIS BLOQUEADORES","ACTIVATE TWO BLOCKERS"),14,GOLD)
	for key: String in host.touch_regions:
		var label: String={"stick":t("DIREÇÃO","STEER"),"action":t("INTERAGIR","INTERACT"),"secondary":"DASH"}[key]
		_control(host.touch_regions[key],label)

func _draw_deep() -> void:
	_txt(Vector2(12,19),"DEEP SIGNAL",17,MINT)
	_txt(Vector2(12,39),"%06d  %s %d%%  %s %d  F%02d/20  %s %d"%[model.score,t("ENERGIA","ENERGY"),int(model.energy),t("CORTES","CUTS"),model.charges,model.level,t("VIDAS","LIVES"),model.lives],14)
	var shift:=Vector2(8,48)
	draw_rect(Rect2(0,48,640,248),Color("#17283C"))
	if model.level>=11:
		# Partial darkness outside the local viewport, keeping a clear hazard lookahead.
		var near_x: float=clampf(model.pos.x+8-160,0,640)
		var far_x: float=clampf(model.pos.x+8+180,0,640)
		draw_rect(Rect2(0,48,near_x,240),Color(0.025,0.04,0.08,0.36))
		draw_rect(Rect2(far_x,48,640-far_x,240),Color(0.025,0.04,0.08,0.36))
	for cell: Vector2i in model.cells:
		var p: Vector2=Vector2(cell)*Deep.TILE+shift
		var box:=Rect2(p,Vector2.ONE*Deep.TILE)
		var breakable: bool=model.cells[cell]=="B"
		draw_rect(box,Color("#78552D") if breakable else Color("#35475C"))
		draw_rect(box,GOLD if breakable else Color("#A9BBD3"),false,2)
		if breakable:
			draw_line(p+Vector2(4,4),p+Vector2(20,20),GOLD,2)
			draw_line(p+Vector2(20,4),p+Vector2(4,20),GOLD,2)
	for cell: Vector2i in model.hazards:
		var p: Vector2=Vector2(cell)*Deep.TILE+shift
		var active: bool=model.hazards[cell]=="W" or model.vapor_active()
		var warning: bool=not active and model.vapor_warning()
		var tile:=Rect2(p,Vector2.ONE*24)
		draw_rect(tile,Color("#963745") if active else Color("#35475C"))
		draw_rect(tile,WHITE if active else (GOLD if warning else Color("#A9BBD3")),false,2)
		if active:
			draw_line(p+Vector2(3,3),p+Vector2(21,21),WHITE,3)
			draw_line(p+Vector2(21,3),p+Vector2(3,21),WHITE,3)
		else:
			_txt(p+Vector2(7,17),"!" if warning else ".",16,WHITE)
	for cell: Vector2i in model.batteries:
		var p: Vector2=model.center(cell)+shift
		draw_rect(Rect2(p-Vector2(8,10),Vector2(16,20)),MINT)
		_txt(p+Vector2(-5,5),"+",16,BG)
	for cell: Vector2i in model.enemies:
		var p: Vector2=model.center(cell)+shift
		draw_circle(p,10,Color("#F28D9B"))
		draw_rect(Rect2(p-Vector2(5,3),Vector2(10,6)),BG)
	var target: Vector2=model.scientist+shift
	draw_circle(target,13,GOLD)
	_txt(target+Vector2(-5,5),"R",16,BG)
	var p: Vector2=model.pos+shift
	draw_rect(Rect2(p-Vector2(8,9),Vector2(16,18)),WHITE)
	draw_rect(Rect2(p+Vector2(-5,-5),Vector2(10,6)),Color("#18283D"))
	if model.vel.y<0:
		draw_line(p+Vector2(0,9),p+Vector2(0,19),MINT,3)
	if model.pulse_flash>0:
		draw_line(p,p+Vector2(model.facing*50,0),MINT,2)
	if model.cut_timer>0:
		var c: Vector2=model.center(model.cut_cell)+shift
		draw_arc(c,36,0,TAU,32,GOLD,2)
		_txt(c+Vector2(-16,-39),"%.1fs"%model.cut_timer,13,GOLD)
	if model.energy<=0:
		_txt(Vector2(10,64),t("SEM ENERGIA ","NO POWER ")+("%.1fs"%model.grace),14,GOLD)
	if model.rescue_hold>0:
		draw_arc(target,18,-PI/2,-PI/2+TAU*model.rescue_hold/0.6,24,MINT,3)
	for key: String in host.touch_regions:
		var label: String={"left":"<","right":">","fire":"JET","action":t("PULSO","PULSE"),"secondary":t("CORTE","CUT")}[key]
		_control(host.touch_regions[key],label)
func _draw_emerald() -> void:
	_txt(Vector2(12,19),"EMERALD EXPEDITION",17,MINT)
	_txt(Vector2(12,39),"%06d  %s %d/4  %s %d/3  %s %d  %s %ds"%[model.score,t("ARTEFATOS","ARTIFACTS"),model.count_region(),t("REG","REG"),model.region,t("VIDAS","LIVES"),model.lives,t("BÔNUS","BONUS"),int(ceil(model.bonus))],13)
	var shift:=Vector2(0,48)
	draw_rect(Rect2(0,48,640,248),Color("#163A39"))
	for i in range(7):
		var x: float=float((i*109+model.room*31)%640)
		draw_rect(Rect2(x,70,16,150),Color("#214F4A"))
		draw_circle(Vector2(x+8,92),32,Color("#28645A"))
	draw_rect(Rect2(0,48+Emerald.FLOOR,640,32),Color("#B29C78"))
	draw_line(Vector2(0,48+Emerald.FLOOR),Vector2(640,48+Emerald.FLOOR),MINT,2)
	if model.gap.size.x>0:
		var gap: Rect2=model.gap
		gap.position+=shift
		draw_rect(gap,BG)
		var bridge:=Rect2(model.bridge_x-14,48+Emerald.FLOOR,28,6)
		if model.collapse<1.0:
			draw_rect(bridge,GOLD if model.collapse>=0.4 else Color("#B79A6B"))
			draw_rect(bridge,WHITE,false,1)
		if model.collapse>=0.4:
			_txt(Vector2(model.bridge_x-10,48+Emerald.FLOOR-10),"!",16,GOLD)
	if model.room in [0,2,4,6]:
		for y in range(60,216,14):
			draw_line(Vector2(309,y+48),Vector2(331,y+48),Color("#D5B47B"),3)
		draw_line(Vector2(309,108),Vector2(309,264),Color("#D5B47B"),2)
		draw_line(Vector2(331,108),Vector2(331,264),Color("#D5B47B"),2)
		_txt(Vector2(337,118),"^" if model.room>=4 else "v",16,WHITE)
	if model.room%4>0:
		_txt(Vector2(12,240),"<",22,WHITE)
	if model.room%4<3:
		_txt(Vector2(615,240),">",22,WHITE)
	if model.room==0:
		draw_rect(Rect2(16,221,58,39),BG)
		_txt(Vector2(20,245),t("BASE","CAMP"),14,MINT)
	if model.room==4:
		draw_rect(Rect2(54,221,52,39),BG)
		_txt(Vector2(60,245),"CP",14,GOLD)
	var id: int=(model.region-1)*8+model.room
	if model.room in [1,3,5,7] and not model.collected.has(id):
		var p: Vector2=model.artifact_pos()+shift
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-12),p+Vector2(11,0),p+Vector2(0,12),p+Vector2(-11,0)]),GOLD)
		draw_arc(p,15,0,TAU,24,WHITE,2)
	if model.hazard:
		var p: Vector2=model.hazard_pos+shift
		draw_rect(Rect2(p-Vector2(14,8),Vector2(28,16)),Color("#F28D9B"))
		draw_rect(Rect2(p-Vector2(14,8),Vector2(28,16)),BG,false,2)
	var p: Vector2=model.pos+shift
	draw_rect(Rect2(p-Vector2(8,10),Vector2(16,20)),WHITE)
	draw_rect(Rect2(p-Vector2(9,11),Vector2(18,5)),MINT)
	if model.immune>0:
		draw_arc(p,15,0,TAU,20,GOLD,2)
	# Mini map of the eight rooms of this region, above the field.
	for cell in range(8):
		var box:=Rect2(468+(cell%4)*22,54+int(cell/4.0)*16,18,12)
		var seen: bool=model.visited.has((model.region-1)*8+cell)
		draw_rect(box,BG if not seen else Color("#52756B"))
		draw_rect(box,WHITE if cell==model.room else Color("#8295B0"),false,2)
		if cell==model.room:
			draw_circle(box.get_center(),3,GOLD)
	for key: String in host.touch_regions:
		var label: String={"stick":t("DIREÇÃO","STEER"),"fire":t("SALTO","JUMP"),"action":t("AÇÃO","ACTION")}[key]
		_control(host.touch_regions[key],label)
