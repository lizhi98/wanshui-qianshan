extends "res://game/remaster/hud.gd"
var guide:PanelContainer
var guide_title:Label
var guide_body:Label
var weather_text:Label
var phase_text:Label
var route_map:Control
func _ready():
	super._ready()
	for child in modern_panel.get_children():child.free()
	modern_panel.hide();objective.get_parent().get_parent().hide();balance.hide()
	var branding=chapter.get_parent().get_parent();_anchor(branding,Vector4(.025,.025,.27,.105))
	var heading = chapter.get_parent().get_child(0)
	heading.add_theme_font_override("font", preload("res://assets/remaster/fonts/MaShanZheng-Regular.ttf"))
	heading.add_theme_font_size_override("font_size",25)
	for label in bottom_bar.find_children("*","Label",true,false):
		if "右键" in label.text:label.text="F 观察　Q 发信号"
		if "WASD" in label.text:label.text="WASD 移动　Shift 奔跑　空格 跳跃"
	chapter.add_theme_font_size_override("font_size",15);health.add_theme_font_size_override("font_size",14);ammo.add_theme_font_size_override("font_size",14)
	guide=_panel(root_control,Vector4(.68,.025,.982,.145),Color(.07,.13,.115,.83));guide.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var box=_vbox(guide);guide_title=_label(box,"",22,PAPER);guide_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;guide_body=_label(box,"",18,GOLD);guide_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	weather_text=_label(root_control,"",14,PAPER);_anchor(weather_text,Vector4(.035,.88,.32,.93))
	phase_text=_label(root_control,"",13,MUTED);_anchor(phase_text,Vector4(.035,.07,.35,.12))
	bark_label.add_theme_font_size_override("font_size",16);_anchor(bark_label,Vector4(.18,.84,.82,.91));bark_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;bark_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	bottom_bar.modulate.a=.88
	center_title.add_theme_font_size_override("font_size",26)
func _process(delta):
	super._process(delta)
	if not guide:return
	hint.hide();marker.hide();health.text="林川 · 探路";ammo.text="同行　阿木 · 周班长"
	guide.visible=mission.started and not overlay.visible and not mission.view.cinematic
	weather_text.visible=guide.visible and mission.stage not in ["INTRO","ROUTE_FINDING"]
	phase_text.hide()
	top_bar.visible=not overlay.visible and not mission.view.cinematic
	bottom_bar.visible=top_bar.visible
	var data=mission.instruction();guide_title.text=data.title;guide_body.text=data.action
	weather_text.text="岩后避风" if mission.weather and mission.weather.sheltered else ("强风 · 靠岩壁，留意雪粒方向" if mission.weather and mission.weather.gust>.65 else "风势稍缓 · 看清落脚处再走")
	if mission.camera_observing:
		guide_body.text="观察中 · 转动鼠标寻找脚印与标记 · F 退出"
		if not mission.observation.focused.is_empty():guide_title.text=mission.world.clues[mission.observation.focused].kind
func _draw_reticle():
	if not mission.started or overlay.visible:return
	var p=root_control.size*.5
	if mission.camera_observing:
		reticle.draw_circle(p,2,GOLD)
		for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:reticle.draw_line(p+direction*8,p+direction*13,PAPER,1)
