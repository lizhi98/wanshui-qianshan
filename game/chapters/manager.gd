extends Node
const CHAPTERS={"bridge":"res://game/v2/main.tscn","snow":"res://game/memorial/main.tscn","legacy":"res://game/snow/main.tscn","fishhook":"res://game/golden_hook/main.tscn"}
static func open_chapter(tree:SceneTree,id:String)->Error:
	if not CHAPTERS.has(id):return ERR_DOES_NOT_EXIST
	return tree.change_scene_to_file(CHAPTERS[id])
func _ready():
	if not Engine.get_write_movie_path().is_empty() and not get_tree().root.has_node("MovieCaptureRenderDriver"):
		get_tree().root.add_child.call_deferred(load("res://qa/movie_capture.gd").new())
	DisplayServer.window_set_title("万水千山 · V4.1.5")
	var args=OS.get_cmdline_user_args()
	if "--v11-navigation" in args and not get_tree().has_meta("v11_navigation"):
		get_tree().set_meta("v11_navigation", true)
		var runner = preload("res://qa/unified_navigation.gd").new()
		get_tree().root.add_child.call_deferred(runner)
		runner.run.call_deferred()
	for flag in ["--chapter3", "--golden-replay", "--golden-smoke", "--v11-action-lab", "--v11-manual-sandbox"]:
		if flag in args:
			call_deferred("launch", "fishhook")
			return
	if "--role-audio-lab" in args:call_deferred("launch","snow");return
	if "--snow-replay" in args or "--smoke-snow" in args or "--legacy-snow" in args:call_deferred("launch","legacy");return
	if "--animation-lab" in args or "--snow" in args or "--memorial-replay" in args or "--smoke-memorial" in args:call_deferred("launch","snow");return
	if "--bridge" in args or "--verify-replay" in args or "--smoke-test" in args:call_deferred("launch","bridge");return
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var menu = preload("res://game/chapters/chapter_menu.tscn").instantiate()
	add_child(menu)
	var entries = menu.get_node("Folio/Column")
	entries.get_node("Bridge").pressed.connect(launch.bind("bridge"))
	entries.get_node("Snow").pressed.connect(launch.bind("snow"))
	entries.get_node("Fishhook").pressed.connect(launch.bind("fishhook"))
	entries.get_node("Exit").pressed.connect(get_tree().quit)
func launch(id:String):open_chapter(get_tree(),id)
