extends CanvasLayer

const PAPER = Color("ece4cf")
const HUD_CARD = preload("res://game/remaster/hud_card.tres")
const GOLD = Color("d7b778")
const MUTED = Color("b2c0b8")
var mission
var root_control: Control
var objective: Label
var chapter: Label
var health: Label
var ammo: Label
var hint: Label
var subtitle: RichTextLabel
var speaker: Label
var dialogue_panel: PanelContainer
var choice_box: VBoxContainer
var dialogue_tools: HBoxContainer
var auto_button: Button
var center_title: Label
var overlay: PanelContainer
var overlay_title: Label
var overlay_body: RichTextLabel
var buttons: VBoxContainer
var reticle: Control
var tint: ColorRect
var top_bar: Control
var bottom_bar: Control
var bark_label: Label
var bark_time := 0.0
var hit_marker := 0.0
var hurt_tint := 0.0
var balance: ProgressBar
var marker: Label
var font = preload("res://assets/remaster/fonts/NotoSansSC.ttf")
var modern_panel: PanelContainer
var scan_status: Label
var scan_button: Button
var finish_button: Button
var enemy_markers: Array[Label]=[]

func _ready():
	font = preload("res://game/chapters/menu_theme.tres").default_font
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	var theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 19
	root_control.theme = theme
	top_bar = Control.new()
	root_control.add_child(top_bar)
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var branding = _panel(top_bar,Vector4(.025,.035,.39,.155))
	var brand_box = _vbox(branding)
	_label(brand_box,"万 水 千 山",26,GOLD)
	chapter = _label(brand_box,"战火中的木板  /  1935 · 大渡河",14,MUTED)
	var quest = _panel(top_bar,Vector4(.62,.035,.975,.155))
	var quest_box = _vbox(quest)
	_label(quest_box,"当 前 目 标",12,GOLD)
	objective = _label(quest_box,"",18,PAPER)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_bar = Control.new()
	root_control.add_child(bottom_bar)
	bottom_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stats = _panel(bottom_bar,Vector4(.025,.865,.29,.97))
	var stats_box = _vbox(stats)
	health = _label(stats_box,"",19,PAPER)
	_label(stats_box,"WASD 移动   Shift 奔跑   E 交互",12,MUTED)
	var weapon = _panel(bottom_bar,Vector4(.735,.865,.975,.97))
	var weapon_box = _vbox(weapon)
	ammo = _label(weapon_box,"",19,PAPER)
	_label(weapon_box,"右键瞄准   左键射击   R 装填",12,MUTED)
	hint = _screen_label(Vector4(.25,.74,.75,.825),19,GOLD)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bark_label = _screen_label(Vector4(.20,.65,.80,.73),18,PAPER)
	bark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bark_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center_title = _screen_label(Vector4(.15,.25,.85,.55),38,PAPER)
	center_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_panel = _panel(root_control,Vector4(.10,.76,.90,.97),Color(.07,.13,.115,.90))
	var dialogue_box = _vbox(dialogue_panel)
	speaker = _label(dialogue_box,"",18,GOLD)
	subtitle = RichTextLabel.new()
	subtitle.fit_content = true
	subtitle.scroll_active = false
	subtitle.custom_minimum_size.y = 65
	subtitle.add_theme_font_size_override("normal_font_size",24)
	subtitle.add_theme_color_override("default_color",PAPER)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_box.add_child(subtitle)
	dialogue_tools = HBoxContainer.new()
	dialogue_tools.alignment = BoxContainer.ALIGNMENT_END
	dialogue_tools.add_theme_constant_override("separation",14)
	dialogue_box.add_child(dialogue_tools)
	_label(dialogue_tools,"点击 / 空格 继续",13,MUTED)
	auto_button = _button(dialogue_tools,"自动：关",func(): mission.dialogue.toggle_auto())
	_button(dialogue_tools,"跳过本段",func(): mission.dialogue.close(true))
	choice_box = VBoxContainer.new()
	root_control.add_child(choice_box)
	_anchor(choice_box,Vector4(.46,.49,.90,.73))
	choice_box.alignment = BoxContainer.ALIGNMENT_END
	choice_box.add_theme_constant_override("separation",8)
	dialogue_panel.hide()
	choice_box.hide()
	reticle = Control.new()
	root_control.add_child(reticle)
	reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticle.draw.connect(_draw_reticle)
	balance = ProgressBar.new()
	root_control.add_child(balance)
	_anchor(balance,Vector4(.37,.67,.63,.695))
	balance.min_value = -1
	balance.max_value = 1
	balance.show_percentage = false
	balance.hide()
	marker = _screen_label(Vector4(0,0,0,0),15,GOLD)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.hide()
	for i in 2:
		var enemy_label=_screen_label(Vector4(0,0,0,0),13,Color("e6a68e"))
		enemy_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		enemy_label.hide()
		enemy_markers.append(enemy_label)
	modern_panel=_panel(root_control,Vector4(.025,.18,.315,.835),Color(.025,.04,.038,.93))
	var modern_box=_vbox(modern_panel)
	_label(modern_box,"2026 · 数字记录",22,GOLD)
	var instructions=_label(modern_box,"选择观察点后按 E 采集。\n拖动鼠标旋转，滚轮缩放。\n虚拟教学场景 · 非现场测绘",13,MUTED)
	instructions.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	scan_status=_label(modern_box,"",14,PAPER)
	for i in 3:
		var index=i
		_button(modern_box,["①  桥头 · 底索","②  河心 · 扶索","③  对岸 · 桥面"][i],func(): mission.modern.select_point(index))
	scan_button=_button(modern_box,"E  采集当前观察点",func(): mission.modern.collect())
	_button(modern_box,"自由环绕 / 结构观察",func(): mission.modern.orbit())
	var row=HBoxContainer.new()
	modern_box.add_child(row)
	_button(row,"底索",func(): mission.modern.inspect_structure(0))
	_button(row,"扶索",func(): mission.modern.inspect_structure(1))
	_button(row,"桥面",func(): mission.modern.inspect_structure(2))
	_button(modern_box,"1935 / 数字重建 对照",func(): mission.modern.compare())
	_button(modern_box,"显示 / 隐藏结构层",func(): mission.modern.toggle_layer())
	finish_button=_button(modern_box,"完成记录",func(): mission.finish_modern())
	modern_panel.hide()
	tint = ColorRect.new()
	root_control.add_child(tint)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(.5,.04,.02,0)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay = _panel(root_control,Vector4(.20,.12,.80,.90),Color(.025,.04,.038,.98))
	overlay.theme = preload("res://game/chapters/menu_theme.tres")
	overlay.remove_theme_stylebox_override("panel")
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var menu_box = _vbox(overlay)
	menu_box.add_theme_constant_override("separation",14)
	overlay_title = _label(menu_box,"",38,GOLD)
	overlay_title.add_theme_font_override("font", preload("res://assets/remaster/fonts/MaShanZheng-Regular.ttf"))
	overlay_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_body = RichTextLabel.new()
	overlay_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_body.scroll_active = true
	overlay_body.bbcode_enabled = true
	overlay_body.add_theme_color_override("default_color",PAPER)
	overlay_body.add_theme_font_size_override("normal_font_size",17)
	menu_box.add_child(overlay_body)
	buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation",8)
	menu_box.add_child(buttons)
	overlay.hide()

func _anchor(node: Control, edges: Vector4):
	node.anchor_left=edges.x
	node.anchor_top=edges.y
	node.anchor_right=edges.z
	node.anchor_bottom=edges.w

func _panel(parent: Control, edges: Vector4, color := Color(.025,.04,.038,.83)) -> PanelContainer:
	var panel = PanelContainer.new()
	parent.add_child(panel)
	_anchor(panel,edges)
	var style = HUD_CARD.duplicate()
	style.bg_color = color
	style.border_color = Color(.67,.55,.32,.7)
	style.border_width_left = 2
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel",style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func _vbox(parent) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation",4)
	parent.add_child(box)
	return box

func _label(parent,text_value: String,size_value: int,color: Color) -> Label:
	var label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size",size_value)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _screen_label(edges: Vector4,size_value: int,color: Color) -> Label:
	var label = _label(root_control,"",size_value,color)
	_anchor(label,edges)
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,.9))
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",2)
	return label

func _button(parent,text_value: String,callback: Callable) -> Button:
	var button = Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 34
	button.add_theme_color_override("font_color",PAPER)
	if parent != buttons:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("253c37")
		style.border_color = Color("88734b")
		style.set_border_width_all(1)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		button.add_theme_stylebox_override("normal",style)
		var hover = style.duplicate()
		hover.bg_color = Color("456252")
		button.add_theme_stylebox_override("hover",hover)
	parent.add_child(button)
	button.pressed.connect(callback)
	return button

func show_line(who: String,text_value: String,responses: Array):
	dialogue_panel.show()
	bark_label.text = ""
	top_bar.hide()
	bottom_bar.hide()
	speaker.text = who
	subtitle.text = text_value
	for child in choice_box.get_children(): child.queue_free()
	choice_box.visible = not responses.is_empty()
	for i in responses.size():
		var index = i
		_button(choice_box,"›  "+responses[i].text,func(): mission.dialogue.choose(index))

func set_text_reveal(count: int): subtitle.visible_characters=count
func set_auto(enabled: bool): auto_button.text="自动：开" if enabled else "自动：关"
func hide_dialogue():
	dialogue_panel.hide()
	choice_box.hide()
	top_bar.show()
	bottom_bar.show()
func dialogue(who: String,text_value: String):
	if text_value.is_empty():
		bark_label.text=""
	else:
		bark_label.text=who+"："+text_value
		bark_time=4.5
func show_menu(title: String,body: String,actions: Array):
	overlay_title.text=title
	overlay_body.text=body
	for child in buttons.get_children(): child.queue_free()
	for entry in actions: _button(buttons,entry[0],entry[1])
	overlay.show()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
func hide_menu(): overlay.hide()
func show_modern():
	modern_panel.show()
	bottom_bar.hide()
	hide_dialogue()
	bottom_bar.hide()
	_anchor(bark_label,Vector4(.34,.72,.96,.83))
func hide_modern():
	modern_panel.hide()
	_anchor(bark_label,Vector4(.20,.65,.80,.73))
func update_modern(count: int,selected: int,distance: float,complete: bool):
	scan_status.text="记录  %d / 3\n观察点 %d · 距离 %.1f m"%[count,selected+1,distance]
	scan_button.disabled=distance>3.2 or selected in mission.modern.scanned
	finish_button.disabled=not complete

func _process(delta):
	if not is_instance_valid(mission.player): return
	objective.text=mission.objective_text()
	chapter.text=mission.chapter_title()
	health.text="体力  %03d" % mission.player.health
	ammo.text=("装填中…" if mission.combat.reloading else "弹药  %02d / %02d" % [mission.combat.ammo,mission.combat.reserve]) if mission.phase==mission.Phase.COMBAT else "同行  林川 · 阿木 · 周班长"
	hint.text=mission.interaction_hint() if not dialogue_panel.visible and not overlay.visible and not modern_panel.visible else ""
	balance.visible=mission.player.climbing and not overlay.visible
	balance.value=mission.player.balance
	if bark_time>0 and not mission.paused:
		bark_time-=delta
		if bark_time<=0: bark_label.text=""
	hurt_tint=move_toward(hurt_tint,0,delta)
	tint.color.a=hurt_tint
	hit_marker=maxf(0,hit_marker-delta)
	reticle.queue_redraw()
	for i in enemy_markers.size():
		var label=enemy_markers[i]
		label.hide()
		if mission.phase==mission.Phase.COMBAT and not overlay.visible and not dialogue_panel.visible:
			var enemy=mission.enemies[i]
			var point=enemy.global_position+Vector3(0,2.1,0)
			if not enemy.dead and not mission.view.camera.is_position_behind(point):
				label.position=mission.view.camera.unproject_position(point)-Vector2(45,20)
				label.size=Vector2(90,28)
				label.text="火力点 %d"%(i+1)
				label.show()
	marker.hide()
	if not overlay.visible and not dialogue_panel.visible and mission.started:
		var point=mission.waypoint()
		if point!=Vector3.INF and not mission.view.camera.is_position_behind(point):
			var screen=mission.view.camera.unproject_position(point)
			var screen_size=root_control.size
			marker.position=Vector2(clampf(screen.x-70,16,screen_size.x-160),clampf(screen.y-55,120,screen_size.y-180))
			marker.size=Vector2(140,50)
			marker.text="◇  %d m" % mission.player.position.distance_to(point)
			marker.show()

func _draw_reticle():
	if not mission.started or mission.dialogue_locked or overlay.visible or mission.phase!=mission.Phase.COMBAT: return
	var p=root_control.size*.5
	reticle.draw_circle(p,2.0,PAPER)
	for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]: reticle.draw_line(p+direction*7,p+direction*12,GOLD,1.5)
	if hit_marker>0:
		for direction in [Vector2(-1,-1),Vector2(-1,1),Vector2(1,-1),Vector2(1,1)]: reticle.draw_line(p+direction*8,p+direction*15,Color("f3c184"),2)
