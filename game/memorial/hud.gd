extends "res://game/snow/hud.gd"
var cinema_back:ColorRect
var credits_back:ColorRect
func _ready():
	super._ready()
	cinema_back=ColorRect.new();root_control.add_child(cinema_back);root_control.move_child(cinema_back,0);cinema_back.color=Color(0,0,0,.65);cinema_back.mouse_filter=Control.MOUSE_FILTER_IGNORE;_anchor(cinema_back,Vector4(.12,.80,.88,.94))
	credits_back=ColorRect.new();root_control.add_child(credits_back);root_control.move_child(credits_back,0);credits_back.color=Color(.015,.025,.035,.86);credits_back.mouse_filter=Control.MOUSE_FILTER_IGNORE;_anchor(credits_back,Vector4(.08,.26,.92,.74))
	center_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	bark_label.add_theme_font_size_override("font_size",20)
func _process(delta):
	super._process(delta)
	health.text="林川 · 抱着衣物" if mission.player.carrying else "林川"
	ammo.text="御寒衣物　余 %d 包"%mission.stock if mission.stage=="CAMP" else "同行 · 照看后面的同志"
	if mission.stage in ["DISCOVERY","SALUTE"]:ammo.text=""
	if mission.action!="":guide_body.text="动作进行中 · 请稍候"
	if not mission.interaction_hint().is_empty() and guide.visible and not mission.camera_observing:guide_body.text=mission.interaction_hint()
	weather_text.visible=weather_text.visible and mission.stage not in ["CAMP","DISCOVERY","SALUTE"]

	var cinema=mission.stage in ["DISCOVERY","SALUTE"] and (mission.flags.get("inspected",false) or mission.action=="inspect")
	if cinema:
		top_bar.hide();bottom_bar.hide();weather_text.hide();phase_text.hide()
		if mission.action in ["inspect","reveal","salute"]:guide.hide()
	cinema_back.visible=cinema and not bark_label.text.is_empty()
	credits_back.visible=mission.outro_active and mission.outro_clock>7 and mission.stage!="COMPLETE"
