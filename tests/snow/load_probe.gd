extends SceneTree
var ok:=false
func _initialize():call_deferred("run")
func run():
	create_timer(20).timeout.connect(func():print("SNOW_LOAD timeout");quit(1))
	var scene=load("res://game/snow/main.tscn")
	if scene==null:quit(1);return
	var game=scene.instantiate()
	if game.get_script()==null:quit(1);return
	root.add_child(game)
	await create_timer(.6).timeout
	if not game.player or not game.world:quit(1);return
	print("SNOW_LOAD PASS route_m=",game.world.route.total," height=",game.world.route.POINTS[-1].y," actors=",game.actors().size())
	game.main_menu()
	for audio in game.find_children("*","AudioStreamPlayer",true,false):audio.stop();audio.stream=null
	game.queue_free();await process_frame;quit()
