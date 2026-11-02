extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.3).timeout
 for a in [g.player,g.amu,g.zhou]:
  var v=a.visual
  for mesh in v.rig.find_children("*shoes*","MeshInstance3D",true,false):
   var min_y=INF;var arrays=mesh.mesh.surface_get_arrays(0);var points=arrays[Mesh.ARRAY_VERTEX];var model=v.global_transform.affine_inverse()*mesh.global_transform
   for p in points:min_y=minf(min_y,(model*p).y)
   var rest=v.to_local(v.skeleton.to_global(v.skeleton.get_bone_global_rest(v.skeleton.find_bone("foot_l")).origin))
   print("SOLE_ASSET ",a.name," ",mesh.name," rest_ankle=",rest," min_sole_y=",min_y," offset=",rest.y-min_y," vertices=",points.size())
 g.queue_free();await process_frame;quit()
