extends Node
const CHAPTERS={"bridge":"res://game/v2/main.tscn","snow":"res://game/memorial/main.tscn","legacy":"res://game/snow/main.tscn"}
static func open_chapter(tree:SceneTree,id:String)->Error:
	if not CHAPTERS.has(id):return ERR_DOES_NOT_EXIST
	return tree.change_scene_to_file(CHAPTERS[id])
func _ready():
	if not Engine.get_write_movie_path().is_empty() and not get_tree().root.has_node("MovieCaptureRenderDriver"):
		get_tree().root.add_child.call_deferred(load("res://qa/movie_capture.gd").new())
	DisplayServer.window_set_title("万水千山 · V4.1.5")
	var args=OS.get_cmdline_user_args()
	if "--role-audio-lab" in args:call_deferred("launch","snow");return
	if "--snow-replay" in args or "--smoke-snow" in args or "--legacy-snow" in args:call_deferred("launch","legacy");return
	if "--animation-lab" in args or "--snow" in args or "--memorial-replay" in args or "--smoke-memorial" in args:call_deferred("launch","snow");return
	if "--bridge" in args or "--verify-replay" in args or "--smoke-test" in args:call_deferred("launch","bridge");return
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var layer=CanvasLayer.new();add_child(layer);var root=Control.new();layer.add_child(root);root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background=ColorRect.new();background.color=Color("111f29");root.add_child(background);background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var map=load("res://game/snow/route_map.gd").new();root.add_child(map);map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);map.modulate.a=.30
	var panel=PanelContainer.new();root.add_child(panel);panel.anchor_left=.27;panel.anchor_right=.73;panel.anchor_top=.18;panel.anchor_bottom=.86
	var style=StyleBoxFlat.new();style.bg_color=Color(.025,.045,.058,.95);style.content_margin_left=30;style.content_margin_right=30;style.content_margin_top=24;style.content_margin_bottom=24;style.set_corner_radius_all(6);panel.add_theme_stylebox_override("panel",style)
	var box=VBoxContainer.new();panel.add_child(box);box.add_theme_constant_override("separation",16)
	var font=load("res://assets/remaster/fonts/NotoSansSC.ttf")
	var title=Label.new();title.text="万 水 千 山";title.add_theme_font_override("font",font);title.add_theme_font_size_override("font_size",34);title.add_theme_color_override("font_color",Color("d7b778"));box.add_child(title)
	var note=Label.new();note.text="同一段长征，两次不同的接力。\n选择章节，继续同行。";note.add_theme_font_override("font",font);note.add_theme_font_size_override("font_size",17);box.add_child(note)
	for entry in [["第一关　飞夺泸定桥","bridge"],["第二关　丰碑 · 雪线之上","snow"]]:
		var id=entry[1];var button=Button.new();button.text=entry[0];button.custom_minimum_size.y=56;button.add_theme_font_override("font",font);button.add_theme_font_size_override("font_size",20);box.add_child(button);button.pressed.connect(func():launch(id))
	var future=Label.new();future.text="第三关 · 后续章节接口已预留";future.add_theme_font_override("font",font);future.add_theme_color_override("font_color",Color("889da4"));box.add_child(future)
	var exit=Button.new();exit.text="退出";exit.custom_minimum_size.y=40;exit.add_theme_font_override("font",font);box.add_child(exit);exit.pressed.connect(func():get_tree().quit())
func launch(id:String):open_chapter(get_tree(),id)
