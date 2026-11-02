extends Control

@onready var bridge: Button = $Folio/Column/Bridge
@onready var snow: Button = $Folio/Column/Snow
@onready var snow_cover: TextureRect = $SnowCover
@onready var caption: Label = $Caption

var preview_button: Button
var transition: Tween
var selected_style: StyleBoxFlat

func _ready():
	selected_style = bridge.get_theme_stylebox("normal").duplicate()
	selected_style.border_color = Color("c8ad78")
	for button: Button in [bridge, snow]:
		button.mouse_entered.connect(button.grab_focus)
		button.focus_entered.connect(_preview.bind(button))
	_preview(bridge)
	bridge.grab_focus()

func _preview(button: Button):
	if button == preview_button:
		return
	if preview_button:
		preview_button.remove_theme_stylebox_override("normal")
	preview_button = button
	button.add_theme_stylebox_override("normal", selected_style)
	var snowy := button == snow
	caption.text = "夹金山   ·   雪线之上" if snowy else "大渡河畔   ·   泸定桥"
	if transition:
		transition.kill()
	var opacity := 1.0 if snowy else 0.0
	if not is_equal_approx(snow_cover.modulate.a, opacity):
		transition = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		transition.tween_property(snow_cover, "modulate:a", opacity, 0.25)
