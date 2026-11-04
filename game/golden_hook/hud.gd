extends CanvasLayer
const FONT=preload("res://assets/remaster/fonts/NotoSansSC.ttf")
const GOLD=Color("cbbb88")
const INK=Color("e5e5ce")
var mission
var root:Control
var objective:Label
var chapter:Label
var inventory:Label
var hint:Label
var marker:Label
var warning:Label
var terrain_warning:=""
var toast_label:Label
var toast_time:=0.0
var dialogue_panel:PanelContainer
var speaker:Label
var subtitle:Label
var dialogue_hint:Label
var menu:PanelContainer
var menu_body:VBoxContainer
var menu_title:Label
var menu_copy:Label
var menu_buttons:VBoxContainer
var map_panel:PanelContainer
var fishing_panel:PanelContainer
var fish_status:Label
var fish_detail:Label
var tension:ProgressBar
var progress:ProgressBar
var charge:ProgressBar
var bars:Array=[]
var task_backdrop:PanelContainer
func label(text:String,size:int,color:=INK)->Label:
	var n=Label.new(); n.text=text
	var face=FontVariation.new(); face.base_font=FONT; face.variation_embolden=.6
	n.add_theme_font_override("font",face); n.add_theme_font_size_override("font_size",size); n.add_theme_color_override("font_color",color)
	n.add_theme_color_override("font_shadow_color",Color(0,.015,.01,.85)); n.add_theme_constant_override("shadow_offset_x",1); n.add_theme_constant_override("shadow_offset_y",2); n.add_theme_constant_override("shadow_outline_size",3)
	return n
func panel(color:=Color(.045,.075,.066,.9))->PanelContainer:
	var n=PanelContainer.new(); var style=StyleBoxFlat.new(); style.bg_color=color
	style.content_margin_left=22; style.content_margin_right=22; style.content_margin_top=16; style.content_margin_bottom=16
	style.border_width_top=1; style.border_color=Color(.64,.65,.45,.4); n.add_theme_stylebox_override("panel",style)
	return n
func _ready():
	root=Control.new(); add_child(root); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	task_backdrop=panel(Color(.025,.05,.04,.72));root.add_child(task_backdrop);task_backdrop.position=Vector2(24,18);task_backdrop.size=Vector2(495,145);task_backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var top=VBoxContainer.new();task_backdrop.add_child(top);top.custom_minimum_size=Vector2(451,0);top.mouse_filter=Control.MOUSE_FILTER_IGNORE
	chapter=label("万水千山  /  第三章",16,GOLD); top.add_child(chapter)
	var title=label("金色的鱼钩",24); top.add_child(title)
	objective=label("",18);objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;objective.custom_minimum_size.x=455;top.add_child(objective)
	inventory=label("",15,Color("b7c1ac")); top.add_child(inventory)
	hint=label("",18); root.add_child(hint); hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM); hint.position=Vector2(330,653); hint.size=Vector2(640,45); hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	marker=label("",15,GOLD); root.add_child(marker); marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; marker.mouse_filter=Control.MOUSE_FILTER_IGNORE
	warning=label("",18,Color("dbc19b")); root.add_child(warning); warning.position=Vector2(44,602)
	toast_label=label("",18); root.add_child(toast_label); toast_label.position=Vector2(700,40); toast_label.size=Vector2(535,75); toast_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	dialogue_panel=panel(Color(.035,.055,.05,.94)); root.add_child(dialogue_panel); dialogue_panel.position=Vector2(210,535); dialogue_panel.size=Vector2(860,151); dialogue_panel.hide()
	var dialog_v=VBoxContainer.new(); dialogue_panel.add_child(dialog_v)
	speaker=label("",17,GOLD); dialog_v.add_child(speaker)
	subtitle=label("",23); subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; subtitle.custom_minimum_size=Vector2(800,57); dialog_v.add_child(subtitle)
	dialogue_hint=label("E / 空格 继续    ·    自动随语音推进",13,Color("94a58f")); dialogue_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; dialog_v.add_child(dialogue_hint)
	menu = PanelContainer.new()
	menu.theme = preload("res://game/chapters/menu_theme.tres")
	root.add_child(menu)
	menu.anchor_left = .20
	menu.anchor_top = .12
	menu.anchor_right = .80
	menu.anchor_bottom = .90
	menu.hide()
	menu_body = VBoxContainer.new()
	menu_body.add_theme_constant_override("separation", 14)
	menu.add_child(menu_body)
	menu_title = label("", 38, GOLD)
	menu_title.add_theme_font_override("font", preload("res://assets/remaster/fonts/MaShanZheng-Regular.ttf"))
	menu_body.add_child(menu_title)
	menu_copy = label("", 17)
	menu_copy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_body.add_child(menu_copy)
	menu_buttons = VBoxContainer.new()
	menu_buttons.add_theme_constant_override("separation", 8)
	menu_body.add_child(menu_buttons)
	map_panel=panel(Color(.04,.065,.06,.96)); root.add_child(map_panel); map_panel.position=Vector2(150,95); map_panel.size=Vector2(980,430); map_panel.hide()
	var mapv=VBoxContainer.new(); map_panel.add_child(mapv)
	mapv.add_child(label("长征叙事地图 · 转向另一支队伍",28,GOLD))
	mapv.add_child(label("1935  中央红军\n泸定桥 ── 雪山 ────────────── 陕北\n              ╲\n1935  红四方面军 · 文学叙事视角\n              草地 · 小梁与老班长\n\n1936  红军三大主力胜利会师",23))
	mapv.add_child(label("线路为叙事示意，非比例地理地图。第三章的主角与前两章不同。",15,Color("a8b69f")))
	fishing_panel=panel(Color(.035,.065,.055,.87)); root.add_child(fishing_panel); fishing_panel.position=Vector2(895,475); fishing_panel.size=Vector2(350,178); fishing_panel.hide()
	var small=fishing_panel.get_theme_stylebox("panel").duplicate();small.content_margin_left=14;small.content_margin_right=14;small.content_margin_top=10;small.content_margin_bottom=10;fishing_panel.add_theme_stylebox_override("panel",small)
	var fv=VBoxContainer.new(); fishing_panel.add_child(fv)
	fish_status=label("",18,GOLD); fv.add_child(fish_status)
	fish_detail=label("",13); fish_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; fish_detail.custom_minimum_size=Vector2(315,31); fv.add_child(fish_detail)
	charge=_bar(fv,"抛竿蓄力",Color("c4b580")); tension=_bar(fv,"鱼线张力  绿色区域为宜",Color("93ad80")); progress=_bar(fv,"收线进度",Color("bdac72"))
	for y in [0,690]:
		var bar=ColorRect.new(); root.add_child(bar); bar.color=Color.BLACK; bar.position=Vector2(0,y); bar.size=Vector2(1280,30); bar.mouse_filter=Control.MOUSE_FILTER_IGNORE; bar.hide(); bars.append(bar)
	root.move_child(menu, -1)
func _bar(parent,text:String,color:Color)->ProgressBar:
	var row=VBoxContainer.new();row.add_theme_constant_override("separation",1);parent.add_child(row);row.add_child(label(text,11,Color("aebba4")))
	var n=ProgressBar.new(); n.custom_minimum_size=Vector2(315,6); n.show_percentage=false; n.max_value=1
	var bg=StyleBoxFlat.new(); bg.bg_color=Color("263c32"); n.add_theme_stylebox_override("background",bg)
	var fill=StyleBoxFlat.new(); fill.bg_color=color; n.add_theme_stylebox_override("fill",fill); row.add_child(n)
	return n
func show_dialogue(who:String,text:String):
	speaker.text=who; subtitle.text=text; dialogue_panel.show(); hint.hide(); marker.hide()
	var width=600.0 if text.length()<19 else 840.0
	var lines=0
	for line in text.split("\n"):lines+=maxi(1,ceili(line.length()*23.0/(width-44)))
	subtitle.custom_minimum_size=Vector2(width-44,lines*29)
	dialogue_panel.size=Vector2(width,80+lines*29);dialogue_panel.position=Vector2((1280-width)*.5,678-dialogue_panel.size.y)
func hide_dialogue(): dialogue_panel.hide(); hint.show()
func toast(text:String,seconds:=3.0): toast_label.text=text; toast_time=seconds
func show_menu(title:String,copy:String,actions:Array):
	menu_title.text=title; menu_copy.text=copy
	for child in menu_buttons.get_children():
		menu_buttons.remove_child(child)
		child.queue_free()
	for entry in actions:
		var button = Button.new()
		button.text = entry[0]
		button.custom_minimum_size.y = 40
		button.pressed.connect(entry[1])
		menu_buttons.add_child(button)
	menu.show(); Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
func show_fishing(f):
	fishing_panel.show()
	var s=f.model.state; var M=f.Model.State
	var titles={M.PREPARE:"抛竿",M.CASTING:"浮标落水",M.WAITING:"观察水面",M.BITE:"浮标沉下去了",M.HOOKED:"鱼已挂住",M.REELING:"稳住这根线",M.CAUGHT:"收进鱼篓",M.ESCAPED:"再试一次"}
	fish_status.text=titles.get(s,"")
	var texts={M.PREPARE:"鼠标调整方向 · 按住左键蓄力，松开抛出",M.CASTING:"留意落点和水波",M.WAITING:"轻晃只是试探。明显下沉时按空格提竿。",M.BITE:"空格 · 提竿",M.HOOKED:"接下来按住左键收线",M.REELING:"左键收线会变紧；松开缓线。保持中段张力。",M.CAUGHT:"E 继续钓鱼    ·    Q 收竿",M.ESCAPED:"E 立即重试    ·    Q 收竿"}
	fish_detail.text=texts.get(s,"")
	charge.value=f.power; tension.value=f.model.tension; progress.value=f.model.progress
	charge.get_parent().visible=s in [M.PREPARE,M.CASTING]
	tension.get_parent().visible=s in [M.HOOKED,M.REELING]
	progress.get_parent().visible=s in [M.HOOKED,M.REELING]
	fishing_panel.size.y=168 if s in [M.HOOKED,M.REELING] else (140 if s in [M.PREPARE,M.CASTING] else 108)
	fishing_panel.position.y=658-fishing_panel.size.y
	var fill=tension.get_theme_stylebox("fill").duplicate(); fill.bg_color=Color("cf8b62") if f.model.tension>.78 or f.model.tension<.23 else Color("93ad80"); tension.add_theme_stylebox_override("fill",fill)
func _process(delta):
	toast_time=maxf(0,toast_time-delta); toast_label.visible=toast_time>0
	if mission:
		var cinematic=mission.busy and mission.view.cinematic and not mission.crafting and not mission.fishing.active
		var playing=mission.started and not menu.visible and (mission.dialogue_rows.is_empty() or mission.walk_and_talk) and not cinematic
		for bar in bars: bar.visible=mission.started and not menu.visible and (cinematic or not mission.dialogue_rows.is_empty())
		fishing_panel.visible=playing and mission.fishing.active
		chapter.get_parent().visible=playing and not mission.fishing.active; task_backdrop.visible=playing and not mission.fishing.active
		hint.visible=playing and not mission.fishing.active; warning.visible=playing and not mission.fishing.active
		if not playing: marker.hide()
	if not mission or not mission.started: return
	warning.text=terrain_warning
	chapter.text="万水千山  /  第三章 · "+mission.act_name()
	objective.text=mission.objective_text()
	var inv=mission.story.inventory
	inventory.text="随身物品  ·  食材 %d    小鱼 %d    鱼汤 %d%s"%[inv.greens,inv.fish,inv.soup,"    纪念鱼钩 1" if inv.keepsake else ("    简易鱼钩 1" if inv.hook else "")]
	hint.text=mission.interaction_hint()
	var point=mission.current_target()
	marker.visible=not dialogue_panel.visible and not menu.visible and not mission.fishing.active and not mission.crafting and not mission.busy and point!=Vector3.INF
	if marker.visible:
		var cam=mission.view.camera
		if not cam.is_position_behind(point):
			var screen=cam.unproject_position(point+Vector3(0,1.0,0)); marker.position=Vector2(clampf(screen.x-85,15,1090),clampf(screen.y-40,180,550)); marker.size=Vector2(175,70)
			marker.text="◇\n%s · %d米"%[mission.target_name(),int(mission.player.position.distance_to(point))]
		else: marker.position=Vector2(1060,320); marker.text="转身寻找 ◇\n"+mission.target_name()
