extends Control
const Host=preload("res://core/session_host.gd")
const Layout=preload("res://core/layout.gd")
const Session=preload("res://core/session.gd")
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
signal exit_requested
signal restart_requested
signal completed(result: Dictionary)
func configure(id: String,level: String,locale: String="pt",prefs: Dictionary={}) -> void:
	game_id=id
	difficulty=level
	language=locale
	left_handed=bool(prefs.get("left_handed",false))
	control_opacity=clampf(float(prefs.get("control_opacity",100))/100.0,0.5,1.0)
	landscape=id!="G03"
func t(pt: String,en: String) -> String:
	return en if language=="en" else pt
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	theme=ThemeFactory.build()
	match game_id:
		"G03": model=Brick.new()
		"G09": model=Orbit.new()
		"G10": model=Shield.new()
		_: return
	host=Host.new()
	add_child(host)
	host.configure(model,Time.get_ticks_usec(),difficulty)
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
		"G03":
			controls={"paddle":Rect2(0,64,360,520),"fire":Rect2(0,584,360,56)}
		"G09":
			if left_handed:
				controls={"left":Rect2(392,296,62,64),"right":Rect2(454,296,62,64),"up":Rect2(516,296,124,64),"fire":Rect2(0,296,120,64),"secondary":Rect2(120,296,120,64)}
			else:
				controls={"left":Rect2(0,296,62,64),"right":Rect2(62,296,62,64),"up":Rect2(124,296,124,64),"fire":Rect2(392,296,120,64),"secondary":Rect2(512,296,128,64)}
		"G10":
			controls={"aim":Rect2(0,48,640,278)}
	host.configure_layout(safe,landscape,controls)
	var rect: Rect2=fitted.rect
	var scale: float=fitted.scale
	var logical_w: float=640 if landscape else 360
	pause_button.position=rect.position+Vector2(logical_w-58,4)*scale
	pause_button.size=Vector2(54,40 if landscape else 54)*scale
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
	var message:=t("Arraste a raquete. Toque SERVIR.","Drag the paddle. Tap SERVE.")
	if game_id=="G09":
		message=t("Gire, acelere, dispare e use DASH.","Rotate, thrust, shoot and DASH.")
	elif game_id=="G10":
		message=t("Toque no campo para interceptar os detritos.","Tap the field to intercept debris.")
	_overlay(message,[[t("Jogar","Play"),_resume],[t("Catálogo","Catalogue"),func(): exit_requested.emit()]])
func pause_game() -> void:
	if is_instance_valid(host):
		host.pause_game()
func _on_paused() -> void:
	_overlay(t("PAUSA","PAUSED"),[[t("Continuar","Resume"),_resume],[t("Reiniciar","Restart"),_confirm_restart],[t("Catálogo","Catalogue"),_confirm_exit]])
func _resume() -> void:
	_clear_overlay()
	host.resume_game()
func _confirm_restart() -> void:
	_overlay(t("Reiniciar a partida?","Restart game?"),[[t("Confirmar","Confirm"),func(): restart_requested.emit()],[t("Cancelar","Cancel"),_on_paused]])
func _confirm_exit() -> void:
	_overlay(t("Abandonar a partida?","Leave game?"),[[t("Confirmar","Confirm"),func(): exit_requested.emit()],[t("Cancelar","Cancel"),_on_paused]])
func _on_result(result: Dictionary) -> void:
	if _complete:
		return
	_complete=true
	pause_button.disabled=true
	completed.emit(result)
	_overlay(t("FIM DE JOGO","GAME OVER")+"\n"+t("Pontos: ","Score: ")+str(result.get("score",0)),[[t("Repetir","Play again"),func(): restart_requested.emit()],[t("Catálogo","Catalogue"),func(): exit_requested.emit()]])
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
	if game_id=="G03":
		_draw_brick()
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
	_control(Rect2(0,528,360,56),t("←  ARRASTE  →","←  DRAG  →"))
	_control(Rect2(0,584,360,56),t("SERVIR","SERVE"))
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
	for key: String in host.touch_regions:
		var label: String={"left":"↶","right":"↷","up":t("PROPULSÃO","THRUST"),"fire":t("TIRO","FIRE"),"secondary":"DASH"}[key]
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
		draw_line(Vector2(threat.start)+shift,p,Color("#704D5C"),1)
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
