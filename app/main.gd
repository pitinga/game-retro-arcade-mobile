extends Control
const Catalog = preload("res://core/catalog.gd")
const Commerce = preload("res://core/commerce.gd")
const Storage = preload("res://core/storage.gd")
var commerce := Commerce.new()
var storage := Storage.new()
var page: String = "catalog"
var selected: String = ""
var level: String = "normal"
var shell: MarginContainer
var content: VBoxContainer
var _status: Label
var active_game: Control
const GameView = preload("res://app/game_view.gd")
const READY_GAMES = ["G03","G09","G10"]
const BG := Color("#101522")
const SURFACE := Color("#202a3c")
const TEXT := Color("#f5f7ff")
const MINT := Color("#63e6c4")
const BORDER := Color("#8295b0")
const GOLD := Color("#ffd166")

func _ready() -> void:
	theme = preload("res://app/arcade_theme.gd").build()
	storage.load_data()
	commerce.begin(Time.get_ticks_msec())
	get_viewport().size_changed.connect(_fit_safe)
	_catalog()

func tr2(pt: String, en: String) -> String:
	return en if storage.prefs.language == "en" else pt

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(10)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func _reset(title: String) -> void:
	for node: Node in get_children():
		remove_child(node)
		node.queue_free()
	var bg := ColorRect.new()
	bg.color = BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell = MarginContainer.new()
	add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shell.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",12)
	scroll.add_child(content)
	_label(title,26,MINT)
	_fit_safe()

func _fit_safe() -> void:
	if not is_instance_valid(shell):
		return
	var padding := Vector4(12,12,12,12)
	if OS.has_feature("android"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		if screen.x > 0 and screen.y > 0 and safe.size.x > 0 and safe.size.y > 0:
			var scale := get_viewport_rect().size / Vector2(screen)
			padding += Vector4(safe.position.x*scale.x,safe.position.y*scale.y,(screen.x-safe.end.x)*scale.x,(screen.y-safe.end.y)*scale.y)
	shell.add_theme_constant_override("margin_left",int(maxf(12,padding.x)))
	shell.add_theme_constant_override("margin_top",int(maxf(12,padding.y)))
	shell.add_theme_constant_override("margin_right",int(maxf(12,padding.z)))
	shell.add_theme_constant_override("margin_bottom",int(maxf(12,padding.w)))

func _label(value: String, font_size: int = 16, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	content.add_child(label)
	return label

func _button(value: String, action: Callable, parent: Control = null) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0,52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_color_override("font_color",TEXT)
	button.add_theme_stylebox_override("normal",_style(SURFACE,BORDER))
	button.add_theme_stylebox_override("hover",_style(SURFACE,MINT))
	button.add_theme_stylebox_override("pressed",_style(BG,MINT))
	button.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,MINT))
	(content if parent == null else parent).add_child(button)
	button.pressed.connect(action)
	return button

func _catalog() -> void:
	active_game=null
	page = "catalog"
	selected = ""
	if OS.has_feature("android"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	_reset("RETRO ARCADE")
	_label(tr2("10 mundos · versão em desenvolvimento","10 worlds · development version"))
	_button(tr2("Configurações","Settings"),_settings)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	content.add_child(grid)
	for item: Dictionary in Catalog.ITEMS:
		var lock_text := " · PRO" if not commerce.can_access(item.id) else ""
		var orientation := tr2(" · Girar"," · Rotate") if item.landscape else ""
		var title: String = item.name+"\n"+str(item[storage.prefs.language])+lock_text+orientation
		var card := _button(title,_details.bind(item.id),grid)
		card.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		card.custom_minimum_size.y = 100
	_button(tr2("Conhecer PRO","About PRO"),_upgrade)

func _details(id: String) -> void:
	var item := Catalog.find(id)
	if item.is_empty():
		_catalog()
		return
	selected = id
	page = "details"
	_reset(item.name)
	_button(tr2("Voltar","Back"),_catalog)
	_label(str(item[storage.prefs.language]))
	_label(tr2("Paisagem · gire o aparelho","Landscape · rotate device") if item.landscape else tr2("Retrato","Portrait"))
	if not commerce.can_access(id):
		_label(tr2("Conteúdo PRO · desbloqueio indisponível nesta versão.","PRO content · unlock unavailable in this build."),16,GOLD)
		_button(tr2("Conhecer PRO","About PRO"),_upgrade)
		return
	var option := OptionButton.new()
	option.custom_minimum_size.y = 52
	for value: String in [tr2("Fácil","Easy"),tr2("Normal","Normal"),tr2("Difícil","Hard")]:
		option.add_item(value)
	option.select(["easy","normal","hard"].find(level))
	content.add_child(option)
	option.item_selected.connect(func(index: int) -> void: level = ["easy","normal","hard"][index])
	var record_key:=id+":"+level+":1"
	_label(tr2("Recorde: ","Best: ")+str(storage.records.get(record_key,0)))
	if id in READY_GAMES:
		_button(tr2("Jogar","Play"),_prepare_game.bind(id))
	else:
		var play := _button(tr2("Em breve · gameplay pendente","Coming soon · gameplay pending"),func() -> void: pass)
		play.disabled=true

func _prepare_game(id: String) -> void:
	if not commerce.can_access(id) or not id in READY_GAMES:
		_details(id)
		return
	if Catalog.find(id).landscape:
		page="prepare"
		_reset(tr2("Gire o aparelho","Rotate your device"))
		_label(tr2("Este jogo usa paisagem. Gire o aparelho antes de jogar.","This game uses landscape. Rotate your device before playing."))
		_button(tr2("Continuar","Continue"),_start_game.bind(id))
		_button(tr2("Voltar","Back"),_details.bind(id))
	else:
		_start_game(id)
func _start_game(id: String) -> void:
	if not commerce.can_access(id) or not id in READY_GAMES:
		_details(id)
		return
	page="game"
	selected=id
	if OS.has_feature("android"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE if Catalog.find(id).landscape else DisplayServer.SCREEN_PORTRAIT)
	for node: Node in get_children():
		remove_child(node)
		node.queue_free()
	shell=null
	var view:=GameView.new()
	view.configure(id,level,storage.prefs.language,storage.prefs)
	active_game=view
	view.exit_requested.connect(_catalog)
	view.restart_requested.connect(_start_game.bind(id))
	view.completed.connect(_game_completed.bind(id,level))
	add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _game_completed(result: Dictionary,id: String,difficulty: String) -> void:
	storage.record(id,difficulty,"1",int(result.get("score",0)))
	# Commerce is intentionally not integrated; no ads in M2.

func _upgrade() -> void:
	page = "upgrade"
	_reset("PRO")
	_label(tr2("Compra única: dez jogos, sem publicidade. Compras não estão habilitadas neste build.","One-time purchase: ten games, no ads. Purchases are not enabled in this build."))
	var purchase := _button(tr2("Desbloquear (indisponível)","Unlock (unavailable)"),func() -> void: pass)
	purchase.disabled = true
	_button(tr2("Voltar","Back"),_catalog)

func _settings() -> void:
	page = "settings"
	_reset(tr2("Configurações","Settings"))
	_button(tr2("Voltar","Back"),_catalog)
	_button(tr2("Idioma: Português","Language: English"),_toggle_language)
	for key: String in ["music","effects","vibration","reduced_motion","left_handed"]:
		var names := {"music":tr2("Música","Music"),"effects":tr2("Efeitos","Effects"),"vibration":tr2("Vibração","Vibration"),"reduced_motion":tr2("Reduzir movimento","Reduce motion"),"left_handed":tr2("Controles para canhotos","Left-handed controls")}
		var check := CheckButton.new()
		check.text = names[key]
		check.custom_minimum_size.y = 52
		check.button_pressed = storage.prefs[key]
		content.add_child(check)
		check.toggled.connect(_pref_changed.bind(key))
	for key: String in ["control_size","control_opacity"]:
		_label(tr2("Tamanho dos controles","Control size") if key == "control_size" else tr2("Opacidade dos controles","Control opacity"))
		var slider := HSlider.new()
		slider.min_value = 50
		slider.max_value = 150 if key == "control_size" else 100
		slider.step = 10
		slider.custom_minimum_size.y = 52
		slider.value = storage.prefs[key]
		content.add_child(slider)
		slider.value_changed.connect(_range_changed.bind(key))
	_status = _label("")
	var restore := _button(tr2("Restaurar (indisponível)","Restore (unavailable)"),func() -> void: pass)
	restore.disabled = true
	_label(tr2("Privacidade: versão offline, sem SDK de anúncios ou cobrança. Política final pendente.","Privacy: offline build, no ad or billing SDK. Final policy pending."))
	_label(tr2("Créditos: projeto Retro Arcade; motor Godot. Arte final e licenças pendentes.","Credits: Retro Arcade project; Godot engine. Final art and licenses pending."))

func _pref_changed(value: bool,key: String) -> void:
	storage.prefs[key] = value
	_save_status()
func _range_changed(value: float,key: String) -> void:
	storage.prefs[key] = int(value)
	_save_status()
func _save_status() -> void:
	var ok := storage.save()
	if is_instance_valid(_status):
		_status.text = "" if ok else tr2("Não foi possível salvar.","Could not save.")
func _toggle_language() -> void:
	storage.prefs.language = "en" if storage.prefs.language == "pt" else "pt"
	storage.save()
	_settings()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back()

func back_action() -> String:
	return "exit" if page == "catalog" else ("pause" if page=="game" else "catalog")
func _handle_back() -> void:
	if back_action() == "exit":
		get_tree().quit()
	elif back_action()=="pause":
		if is_instance_valid(active_game):
			active_game.call("pause_game")
	else:
		_catalog()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_handle_back()
		get_viewport().set_input_as_handled()
