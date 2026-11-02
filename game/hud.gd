extends CanvasLayer

var mission
var root_control: Control
var objective: Label
var chapter: Label
var health: Label
var ammo: Label
var hint: Label
var subtitle: Label
var speaker: Label
var dialogue_panel: Panel
var center_title: Label
var overlay: Panel
var overlay_title: Label
var overlay_body: Label
var buttons: VBoxContainer
var reticle: Control
var tint: ColorRect
var hit_marker := 0.0
var hurt_tint := 0.0
var balance: Label
var marker_labels: Array[Label] = []
var font: SystemFont

func _ready():
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "Arial"])
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	panel(Rect2(24,24,380,80), Color(0.035,0.065,0.06,0.84))
	label("万水千山", Vector2(42,30),24,Color("e5dac0"))
	chapter = label("战火中的木板  /  泸定桥",Vector2(43,65),16,Color("aebfb4"))
	panel(Rect2(856,24,400,80),Color(0.035,0.065,0.06,0.84))
	label("当前目标",Vector2(876,34),13,Color("c0a36c"))
	objective = label("",Vector2(876,56),18,Color("f0e6cc"))
	panel(Rect2(24,614,320,80),Color(0.035,0.065,0.06,0.86))
	health = label("",Vector2(43,627),24,Color("e6d9ba"))
	label("WASD 移动  ·  Shift 奔跑  ·  Space 跳跃",Vector2(43,666),12,Color("a4b7ad"))
	panel(Rect2(995,614,261,80),Color(0.035,0.065,0.06,0.86))
	ammo = label("",Vector2(1014,627),25,Color("ead8b1"))
	label("右键瞄准  ·  左键射击  ·  R 装填",Vector2(1014,667),12,Color("a4b7ad"))
	hint = label("",Vector2(370,524),20,Color("f5dfaa"))
	hint.size = Vector2(540,56)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance = label("",Vector2(430,478),18,Color("f5dfaa"))
	balance.size = Vector2(420,40)
	balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_panel = panel(Rect2(310,554,660,126),Color(0.028,0.055,0.052,0.94))
	speaker = label("",Vector2(334,568),17,Color("d5b676"))
	subtitle = label("",Vector2(334,596),22,Color("eee6d0"))
	subtitle.size = Vector2(610,68)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_panel.visible = false
	speaker.visible = false
	subtitle.visible = false
	center_title = label("",Vector2(220,210),40,Color("f2e1bb"))
	center_title.size = Vector2(840,230)
	center_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_title.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8))
	center_title.add_theme_constant_override("shadow_offset_x",2)
	center_title.add_theme_constant_override("shadow_offset_y",3)
	reticle = Control.new()
	reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(reticle)
	reticle.draw.connect(_draw_reticle)
	for i in 2:
		var marker = label("",Vector2.ZERO,13,Color("ddaa78"))
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.size = Vector2(150,45)
		marker_labels.append(marker)
	tint = ColorRect.new()
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.55,0.03,0.01,0)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(tint)
	overlay = panel(Rect2(300,145,680,452),Color(0.035,0.065,0.06,0.96))
	overlay_title = label("",Vector2(340,174),30,Color("eddbb2"))
	overlay_title.size = Vector2(600,60)
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_body = label("",Vector2(358,236),18,Color("b8c7bd"))
	overlay_body.size = Vector2(570,185)
	overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buttons = VBoxContainer.new()
	buttons.position = Vector2(422,438)
	buttons.size = Vector2(436,140)
	buttons.add_theme_constant_override("separation",12)
	root_control.add_child(buttons)
	show_menu("万水千山：战火中的木板", "1935 年 5 月 29 日 · 大渡河\n\n作为一名协助铺桥的普通战士，你将与战友一起掩护、运板、修桥，攀过最后一段铁索。\n\n虚构人物的短篇故事 · 完整关卡试玩",[["开始行动",mission.begin],["退出",mission.quit_game]])

func panel(rect: Rect2, color: Color) -> Panel:
	var node = Panel.new()
	node.position = rect.position
	node.size = rect.size
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 2
	style.border_color = Color("8c774f")
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	node.add_theme_stylebox_override("panel",style)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(node)
	return node

func label(text_value: String, position_value: Vector2, font_size: int, color: Color) -> Label:
	var node = Label.new()
	node.text = text_value
	node.position = position_value
	node.add_theme_font_override("font",font)
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(node)
	return node

func show_menu(title_value: String, body: String, choices: Array):
	overlay.visible = true
	overlay_title.visible = true
	overlay_body.visible = true
	buttons.visible = true
	overlay_title.text = title_value
	overlay_body.text = body
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	for choice in choices:
		var button = Button.new()
		button.text = choice[0]
		button.custom_minimum_size = Vector2(420,42)
		button.add_theme_font_override("font",font)
		button.add_theme_font_size_override("font_size",18)
		button.pressed.connect(choice[1])
		buttons.add_child(button)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func hide_menu():
	overlay.visible = false
	overlay_title.visible = false
	overlay_body.visible = false
	buttons.visible = false

func dialogue(who: String, text_value: String):
	dialogue_panel.visible = not text_value.is_empty()
	speaker.visible = dialogue_panel.visible
	subtitle.visible = dialogue_panel.visible
	speaker.text = who
	subtitle.text = text_value

func _draw_reticle():
	if mission.phase != mission.Phase.COMBAT or mission.paused or mission.failed:
		return
	var c = Vector2(640,360)
	var color = Color("fff0d0") if hit_marker<=0 else Color("e9905c")
	var spread = 5 if mission.player.aiming else 12
	reticle.draw_circle(c,1.5,color)
	for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		reticle.draw_line(c+direction*spread,c+direction*(spread+7),color,1.4)

func _process(delta):
	hit_marker = maxf(0,hit_marker-delta)
	hurt_tint = maxf(0,hurt_tint-delta*0.45)
	tint.color.a = hurt_tint
	reticle.queue_redraw()
	objective.text = mission.objective_text()
	health.text = "生命  %03d" % mission.player.health
	ammo.text = "装填中…" if mission.combat.reloading else "%02d / %02d   步枪" % [mission.combat.ammo,mission.combat.reserve]
	hint.text = mission.interaction_hint()
	balance.text = "W 前进 / S 后退  ·  A / D 调整身体\n平衡  %d%%" % int((1.0-absf(mission.player.balance))*100) if mission.player.climbing else ""
	for i in marker_labels.size():
		var enemy = mission.enemies[i]
		var camera = mission.view.camera
		var point = enemy.position+Vector3(0,2.05,0)
		var marker = marker_labels[i]
		marker.visible = mission.phase == mission.Phase.COMBAT and not enemy.dead and not camera.is_position_behind(point) and not mission.paused
		if marker.visible:
			marker.position = camera.unproject_position(point)-Vector2(75,25)
			marker.text = "守军  %d" % enemy.health
