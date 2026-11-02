extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v413_stuck_probe.json";g.begin();g.restore_checkpoint(JSON.parse_string(FileAccess.get_file_as_string("res://tests/v413/stuck_checkpoint.json")));g.set_process(false);g.audio.clear_voice()
 for j in 3:
  await create_timer(1).timeout;var a=g.young;print("STUCK ",a.position," wanted=",a.horizontal_velocity," safe=",a.safe_velocity," target=",a.route[a.route_index]," floor=",a.get_floor_normal())
  for i in a.get_slide_collision_count():
   var c=a.get_slide_collision(i);print("COLLISION ",c.get_position()," ",c.get_normal()," ",c.get_collider().get_parent().name)
  var direction=a.horizontal_velocity.normalized()
  for i in range(-2,7):
   var p=a.position+direction*float(i)*.2;var hit=g.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*2,p-Vector3.UP*2,1));print("GROUND ",i," ",hit)
 g.main_menu();g.queue_free();await process_frame;quit()
