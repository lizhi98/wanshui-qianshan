extends SceneTree
# Restore a failed test snapshot solely to diagnose physical paths.
var g
func _initialize():call_deferred("run")
func run():
	g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.3).timeout
	var data=JSON.parse_string(FileAccess.get_file_as_string("user://memorial_input_replay_v41.json"));g.restore_checkpoint(data)
	for sample in 6:
		await create_timer(3).timeout
		for a in g.actors():
			if not a.moving:continue
			var collider=""
			if a.get_slide_collision_count()>0:collider=str(a.get_slide_collision(0).get_collider().get_parent())
			print("NAV ",sample," ",a.name," p=",a.position," goal=",a.route[a.route_index] if a.route_index<a.route.size() else "end"," collision=",collider," floor=",a.is_on_floor())
	g.main_menu();g.queue_free();await process_frame;quit()
