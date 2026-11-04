extends SceneTree
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func run():
	var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await process_frame;g.save_store.path="user://memorial_v11_slope_fixture.json";g.begin();g.set_process(false);g.action="";g.flags.intro_done=true;g.stage="MARCH"
	var npc=g.young
	g.player.position=Vector3(-12,g.world.height_at(Vector3(-12,0,-62))+.01,-62);g.player.locked=true
	npc.restore();npc.position=Vector3(-6.979541,22.27508,-44.67912)
	npc.walk([Vector3(-10.5,24,-47.5)],1.85)
	var start=npc.position
	await create_timer(6).timeout
	print("SLOPE_DIAGNOSTIC start=",start," finish=",npc.position," floor=",npc.is_on_floor()," normal=",npc.get_floor_normal()," velocity=",npc.velocity)
	check(npc.position.distance_to(start)>1.5,"a memorial NPC can leave the reproducible smooth-slope stall")
	check(npc.is_on_floor(),"the slope repair retains grounded physical movement")
	g.queue_free();await process_frame;await process_frame;OS.delay_msec(80);DirAccess.remove_absolute(ProjectSettings.globalize_path("user://memorial_v11_slope_fixture.json"));quit(1 if errors else 0)
