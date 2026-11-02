extends "res://game/remaster/hud.gd"
var task_detail:Label
var task_progress:ProgressBar
var classify_buttons:Array[Button]=[]
var place_buttons:Array[Button]=[]
var point_buttons:Array[Button]=[]
var compare_button:Button
var guidance=preload("res://game/v2/guidance.gd").new()
var guide_panel:PanelContainer
var guide_tag:Label
var guide_title:Label
var guide_body:Label
var guide_action:Label
var guide_progress:ProgressBar
var target_panel:PanelContainer
var target_text:Label
var direction_panel:PanelContainer
var direction_text:Label
var speech_panel:PanelContainer
var beacon:Node3D
var trail:Array[MeshInstance3D]=[]
var current_guide:Dictionary={}
var guide_clock:=0.0
var compact_shell_done:=false
func _ready():
	super._ready()
	guidance.setup(mission)
	if not InputMap.has_action("guide_detail"):
		InputMap.add_action("guide_detail")
		var key=InputEventKey.new(); key.physical_keycode=KEY_TAB; InputMap.action_add_event("guide_detail",key)
	task_detail=_screen_label(Vector4(.64,.17,.975,.29),14,MUTED)
	task_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	task_progress=ProgressBar.new(); root_control.add_child(task_progress)
	_anchor(task_progress,Vector4(.64,.30,.975,.315)); task_progress.max_value=1; task_progress.show_percentage=false
	for child in modern_panel.get_children():child.free()
	modern_panel.hide()
func update_modern(_count:int,_selected:int,_distance:float,_complete:bool):
	modern_panel.hide()
func _process(delta):
	super._process(delta)
	if not guide_panel: _make_guidance()
	if not compact_shell_done: _compact_shell()
	var visible_task=mission.started and not overlay.visible and not dialogue_panel.visible and not mission.paused
	task_detail.hide(); task_progress.hide(); hint.hide(); marker.hide()
	objective.get_parent().get_parent().hide()
	guide_panel.visible=visible_task
	direction_panel.visible=visible_task and not modern_panel.visible
	speech_panel.visible=visible_task and not bark_label.text.is_empty()
	if not visible_task:
		target_panel.hide(); beacon.hide()
		for dot in trail: dot.hide()
		return
	guide_clock+=delta
	current_guide=guidance.data()
	var d=current_guide
	guide_tag.text=d.tag; guide_title.text=d.title; guide_body.text=d.body; guide_action.text=d.action
	guide_progress.value=d.progress
	var detail=Input.is_action_pressed("guide_detail")
	guide_body.visible=detail; guide_tag.visible=detail; guide_progress.visible=detail
	_anchor(guide_panel,Vector4(.70,.02,.985,.32) if detail else Vector4(.70,.02,.985,.145))
	target_panel.hide()
	if mission.get("assault") and mission.assault.active:
		ammo.text="弹药 %02d  · 通过 %d"%[mission.combat.ammo,mission.assault.passed]
	for i in enemy_markers.size():
		var pin=enemy_markers[i]; pin.hide()
		var enemy=mission.enemies[i]
		var point=enemy.global_position+Vector3(0,2.1,0)
		if mission.player.aiming and not enemy.dead and not mission.view.camera.is_position_behind(point):
			pin.text="◆"; pin.add_theme_font_size_override("font_size",9)
			pin.position=mission.view.camera.unproject_position(point)-Vector2(6,8); pin.size=Vector2(12,12); pin.show()
	_update_wayfinding(d)
	if mission.get("recon") and mission.recon.observing: reticle.queue_redraw()

func _card(parent:Node,pos:Vector4)->PanelContainer:
	var card=PanelContainer.new(); parent.add_child(card); _anchor(card,pos)
	card.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style=StyleBoxFlat.new(); style.bg_color=Color(.025,.04,.045,.38)
	style.border_color=Color(.78,.7,.5,.32); style.set_border_width_all(1); style.set_corner_radius_all(4)
	style.content_margin_left=8; style.content_margin_right=8; style.content_margin_top=5; style.content_margin_bottom=5
	card.add_theme_stylebox_override("panel",style)
	return card

func _make_guidance():
	guide_panel=_card(root_control,Vector4(.70,.02,.985,.145))
	var box=_vbox(guide_panel); box.add_theme_constant_override("separation",3)
	guide_tag=_label(box,"",11,Color("f5ca72"))
	guide_title=_label(box,"",16,Color.WHITE); guide_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	guide_body=_label(box,"",13,Color("e3edf0")); guide_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	guide_action=_label(box,"",13,Color("ffe293")); guide_action.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	guide_progress=ProgressBar.new(); guide_progress.max_value=1; guide_progress.show_percentage=false; guide_progress.custom_minimum_size.y=6; box.add_child(guide_progress)
	target_panel=_card(root_control,Vector4(0,0,0,0))
	target_text=_label(target_panel,"",12,Color.WHITE); target_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	direction_panel=_card(root_control,Vector4(.33,.951,.67,.985))
	direction_text=_label(direction_panel,"",12,Color("fff0b8")); direction_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	speech_panel=_card(root_control,Vector4(.26,.865,.74,.932))
	bark_label.reparent(speech_panel); _anchor(bark_label,Vector4(0,0,1,1)); bark_label.add_theme_font_size_override("font_size",16)
	beacon=Node3D.new(); beacon.name="TutorialGoalBeacon"; mission.add_child(beacon)
	var mat=StandardMaterial3D.new(); mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_color=Color(1,.82,.42,.42); mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	var ring=MeshInstance3D.new(); ring.mesh=TorusMesh.new(); ring.mesh.inner_radius=.28; ring.mesh.outer_radius=.31; ring.mesh.rings=32; ring.material_override=mat; beacon.add_child(ring)
	for i in 4:
		var dot=MeshInstance3D.new(); dot.mesh=TorusMesh.new(); dot.mesh.inner_radius=.025; dot.mesh.outer_radius=.04; dot.mesh.rings=12; dot.mesh.ring_segments=6; dot.material_override=mat; mission.add_child(dot); trail.append(dot)

func _update_wayfinding(d:Dictionary):
	var point:Vector3=d.point
	var next:Vector3=d.next
	var is_walk=d.mode=="walk"
	beacon.visible=point!=Vector3.INF and is_walk
	if beacon.visible:
		beacon.position=Vector3(point.x,maxf(0,point.y-1)+.035,point.z)
		beacon.scale=Vector3.ONE*(1.0+sin(guide_clock*3)*.025)
	for i in trail.size():
		var dot=trail[i]
		dot.visible=is_walk and next!=Vector3.INF
		if dot.visible:
			var start=mission.player.position; var diff=Vector3(next.x-start.x,0,next.z-start.z)
			var distance=minf(diff.length(),8.0)
			dot.position=start+diff.normalized()*((i+1)*distance/11.0); dot.position.y=maxf(-.005,start.y+.05)
			dot.visible=distance>1.2
	if point==Vector3.INF:
		target_panel.hide(); direction_panel.hide(); return
	var focus=next if is_walk else point
	target_panel.hide()
	var target_label=d.target if not is_walk or next.distance_to(point)<1.5 else "下一路标"
	var local_direction=(focus-mission.player.position).rotated(Vector3.UP,-mission.view.rotation.y)
	var heading="↑ 前方" if local_direction.z<0 else "↓ 身后，请转身"
	if absf(local_direction.x)>absf(local_direction.z)*.65:
		if local_direction.x>0: heading="→ 右前方" if local_direction.z<0 else "↘ 右后方"
		else: heading="← 左前方" if local_direction.z<0 else "↙ 左后方"
	direction_text.text=(heading+" · "+target_label+" %.0fm"%Vector2(mission.player.position.x-focus.x,mission.player.position.z-focus.z).length()) if is_walk else ("◎ 对准目标" if d.mode in ["observe","aim"] else "Tab · 操作详情")

func _draw_reticle():
	super._draw_reticle()
	if not mission.started or overlay.visible: return
	if mission.get("assault") and mission.assault.active:
		var center=root_control.size*.5
		if mission.player.aiming:
			reticle.draw_circle(center,1.5,PAPER)
			for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]: reticle.draw_line(center+direction*6,center+direction*10,GOLD,1)
	if mission.get("recon") and mission.recon.observing:
		var center=root_control.size*.5
		reticle.draw_arc(center,18,0,TAU,48,GOLD,1.5)
		reticle.draw_line(center-Vector2(8,0),center+Vector2(8,0),PAPER)
		reticle.draw_line(center-Vector2(0,8),center+Vector2(0,8),PAPER)

# The legacy modern UI used screen-relative anchors on the bark label.
# In V2.2 the same label belongs to a subtitle card, so restore local layout.
func _restore_speech_layout():
	if is_instance_valid(speech_panel):
		_anchor(speech_panel,Vector4(.42,.86,.985,.93) if modern_panel.visible else Vector4(.26,.865,.74,.932))
		bark_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		speech_panel.queue_sort()
func show_modern():
	super.show_modern()
	_restore_speech_layout()
func hide_modern():
	super.hide_modern()
	_restore_speech_layout()

func _compact_shell():
	compact_shell_done=true
	var brand=chapter.get_parent().get_parent()
	_anchor(brand,Vector4(.015,.018,.25,.088))
	var brand_style=StyleBoxFlat.new(); brand_style.bg_color=Color(.02,.03,.035,.22)
	brand_style.content_margin_left=7; brand_style.content_margin_top=2
	brand.add_theme_stylebox_override("panel",brand_style)
	var labels=brand.find_children("*","Label",true,false)
	if not labels.is_empty(): labels[0].text="飞夺泸定桥"; labels[0].add_theme_font_size_override("font_size",18)
	chapter.add_theme_font_size_override("font_size",11)
	for pair in [[health,Vector4(.015,.94,.23,.99)],[ammo,Vector4(.775,.94,.985,.99)]]:
		var label=pair[0]; var card=label.get_parent().get_parent()
		_anchor(card,pair[1]); card.add_theme_stylebox_override("panel",brand_style.duplicate())
		label.add_theme_font_size_override("font_size",13)
		for child in label.get_parent().get_children():
			if child!=label: child.hide()
	_anchor(modern_panel,Vector4(.015,.13,.31,.90))
	for button in modern_panel.find_children("*","Button",true,false): button.add_theme_font_size_override("font_size",14)

func _exit_tree():
	if is_instance_valid(beacon): beacon.queue_free()
	for dot in trail:
		if is_instance_valid(dot): dot.queue_free()
