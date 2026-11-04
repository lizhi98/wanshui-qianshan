extends SceneTree
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);g.store.path="user://golden_hook_v11_hook_test.json";g.begin_chapter(true)
	check(g.world.work_hook.has_method("set_bend"),"the same needle has an actual controllable bending surface")
	check(g.world.work_needle==g.world.work_hook,"heat and bend operate on the unique persistent hook object")
	check(g.world.work_hook.get_parent()==g.world.items.needle,"the unique needle begins inside its actual cloth tool pouch")
	var props=load("res://game/golden_hook/props.gd").new();var morph=false
	if props.has_method("parcel"):
		var parcel=props.parcel(g)
		for mesh in parcel.find_children("*","MeshInstance3D",true,false):morph=morph or mesh.find_blend_shape_by_name("Wrapped")>=0
	check(morph,"the keepsake wraps with a deforming cloth mesh")
	g.queue_free();await process_frame;await process_frame;OS.delay_msec(80);DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_v11_hook_test.json"));quit(1 if errors else 0)
