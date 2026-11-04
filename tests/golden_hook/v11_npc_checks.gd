extends SceneTree
var errors:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);g.store.path="user://golden_hook_v11_npc_test.json";g.begin_chapter(true);g.player.locked=true
	var npc=g.shi;npc.visual.reset_pose();npc.position=g.world.at_ground(Vector3(-25,0,2))
	var barrier=StaticBody3D.new();g.add_child(barrier);barrier.position=g.world.at_ground(Vector3(-25,0,0))+Vector3(0,1,0)
	var collider=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(4,3,.3);collider.shape=box;barrier.add_child(collider)
	npc.walk([g.world.at_ground(Vector3(-25,0,-2))],1.85)
	await create_timer(3).timeout
	check(npc.position.z>.30,"NPC motion respects physical scenery instead of walking through it")
	check(npc.is_on_floor(),"the NPC's physical capsule remains on wetland collision")
	check(npc.get("avoidance") is NavigationAgent3D,"chapter NPCs use V4.1.3 RVO avoidance parameters")
	g.queue_free();await process_frame;await process_frame;OS.delay_msec(80);DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_v11_npc_test.json"));quit(1 if errors else 0)
