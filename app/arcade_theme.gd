extends RefCounted
const BG := Color("#101522")
const SURFACE := Color("#202A3C")
const TEXT := Color("#F5F7FF")
const MUTED := Color("#B5C3D8")
const MINT := Color("#63E6C4")
const BORDER := Color("#8295B0")
static func box(fill: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color=fill
	s.border_color=border
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	s.content_margin_left=10
	s.content_margin_right=10
	s.content_margin_top=8
	s.content_margin_bottom=8
	return s
static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size=16
	for kind: String in ["Button","CheckButton","OptionButton"]:
		for state: String in ["normal","hover","pressed","disabled","focus"]:
			t.set_stylebox(state,kind,box(BG if state in ["pressed","disabled","focus"] else SURFACE,MINT if state in ["hover","focus"] else BORDER))
		for key: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:
			t.set_color(key,kind,MUTED if key=="font_disabled_color" else TEXT)
	t.set_color("font_color","Label",TEXT)
	t.set_stylebox("panel","PopupMenu",box(SURFACE,BORDER))
	t.set_stylebox("hover","PopupMenu",box(BG,MINT))
	t.set_color("font_color","PopupMenu",TEXT)
	t.set_color("font_hover_color","PopupMenu",TEXT)
	t.set_stylebox("slider","HSlider",box(BG,BORDER))
	t.set_stylebox("grabber_area","HSlider",box(MINT,MINT))
	t.set_stylebox("grabber_area_highlight","HSlider",box(MINT,MINT))
	return t
