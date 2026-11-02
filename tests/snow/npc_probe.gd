extends SceneTree
func _initialize():call_deferred("run")
func run():
	var game=load("res://game/snow/main.tscn").instantiate();root.add_child(game);await create_timer(.3).timeout;game.save_store.path="user://snow_npc_probe.json";game.begin();game.intro_clock=23;game._intro(0);game.stage="SUMMIT";game.flags.at_pass=true;game.player.locked=true
	var a=game.amu;a.position=game.world.route.POINTS[22]+Vector3.UP*.2;a.walk(game._party_path(23,27,0),2.85)
	for i in 40:
		await create_timer(1).timeout
		print("NPC_PROBE ",i," pos=",a.position," target=",a.route[a.route_index] if a.route_index<a.route.size() else Vector3.ZERO," vel=",a.velocity," floor=",a.is_on_floor()," jumps=",a.jumps," failed=",game.failed)
		for j in a.get_slide_collision_count():
			var hit=a.get_slide_collision(j);print("CONTACT normal=",hit.get_normal()," collider=",hit.get_collider()," at=",hit.get_position())
	game.queue_free();await process_frame;quit()
