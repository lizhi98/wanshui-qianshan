extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.3).timeout
 var lab=load("res://qa/animation_lab.gd").new();root.add_child(lab);lab.g=g;lab.set_process(false);lab.lab_ground();await physics_frame;await process_frame
 for x in [10,30,45,60]:
  var hit=g.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,210,500),Vector3(x,199,500),1));print("RAMP_RAY ",x," ",hit)
 g.queue_free();lab.queue_free();await process_frame;quit()
