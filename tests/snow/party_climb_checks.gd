extends SceneTree
# Isolated NPC climb fixture; not a substitute for input-driven acceptance.
func _initialize():call_deferred("run")
func run():
	var game=load("res://game/snow/main.tscn").instantiate();root.add_child(game);await create_timer(.3).timeout;game.save_store.path="user://snow_party_climb_fixture.json";game.begin();game.intro_clock=23;game._intro(0);game.stage="SUMMIT";game.flags.at_pass=true;game.player.locked=true
	for i in game.actors().size():
		var a=game.actors()[i];a.position=game.world.route.POINTS[20]+Vector3(float(i%2)*.2,.2,float(i)*.4);a.walk(game._party_path(21,27,i),2.85)
	var clock=0.0
	while clock<85 and not game._gathered():await create_timer(.2).timeout;clock+=.2
	var failed=false
	for a in game.actors():
		var okay=not a.moving and a.position.distance_to(game.world.route.POINTS[-1])<5.5 and a.jumps>=3
		print(("PASS " if okay else "FAIL "),"NPC crosses two gaps and rock step to gather: ",a.name," pos=",a.position," jumps=",a.jumps," waypoint=",a.route_index)
		if not okay:failed=true
	game.main_menu();game.audio.clear_voice()
	for audio in game.find_children("*","AudioStreamPlayer",true,false):audio.stop();audio.stream=null
	game.queue_free();await process_frame;quit(1 if failed else 0)
