extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.3).timeout
 var s=g.director.commander.visual.skeleton
 for name in ["hand_r","index_01_r","index_02_r","index_03_r","pinky_01_r","thumb_01_r"]:
  var b=s.find_bone(name);print("REST ",name," ",b," ",s.get_bone_rest(b)," GLOBAL ",s.get_bone_global_rest(b))
 g.queue_free();await process_frame;quit()
