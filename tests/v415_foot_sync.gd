extends SceneTree
# Release-pack diagnostic; ordinary movement on an isolated flat snow fixture.
var g
var rows:Array=[]
var observed:=0
var phase:="setup"
var failures:=0
func _initialize():call_deferred("run")
func _process(_delta):
 if not g:return false
 var a=g.player;var center=a.position+Vector3.UP
 g.view.camera.global_position=center+Vector3(3,1.1,3);g.view.camera.look_at(center)
 while observed<g.audio.footstep_audit.size():
  var event=g.audio.footstep_audit[observed];observed+=1
  var sk=a.visual.skeleton;var bone=sk.find_bone("foot_"+event.side);var p=sk.to_global(sk.get_bone_global_pose(bone).origin)
  var hit=root.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*.6,p-Vector3.UP*.8,1))
  var gap=absf(p.y-hit.position.y-a.visual.sole_offset(event.side)) if not hit.is_empty() else 100.0
  rows.append({"phase":phase,"side":event.side,"file":event.file,"sole_gap":gap,"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"generic_loop_playing":a.get_node("SoundFootsteps").playing,"generic_bus_playing":get_root().get_node("Audio").get_children().any(func(x):return x is AudioStreamPlayer and x.playing)})
 return false
func check(ok,label):
 print(("PASS " if ok else "FAIL ")+label)
 if not ok:failures+=1
func run():
 g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v415_foot_sync.json";g.begin();g.flags.intro_done=true;g.set_process(false);g.audio.clear_voice();g.audio.music_volume=0;g.audio.wind.stop();g.world.hide();g.hud.root_control.hide();g.crowd.set_physics_process(false)
 if not Engine.get_write_movie_path().is_empty():root.add_child(load("res://qa/movie_capture.gd").new())
 var floor_mesh=MeshInstance3D.new();floor_mesh.name="SnowTrailAudioFixture";floor_mesh.mesh=BoxMesh.new();floor_mesh.mesh.size=Vector3(180,.5,40);floor_mesh.position=Vector3(0,199.75,500);var m=StandardMaterial3D.new();m.albedo_color=Color(.88,.91,.93);floor_mesh.material_override=m;g.add_child(floor_mesh);floor_mesh.create_trimesh_collision()
 g.player.restore(Vector3(-50,200.02,500));g.player.rotation.y=PI/2;g.player.rotation_direction=PI/2;g.player.locked=false;g.view.cinematic=true;g.view.set_process_input(false);g.view.rotation.y=-PI/2
 for action in InputMap.get_actions():InputMap.action_erase_events(action)
 phase="idle";await create_timer(2).timeout;check(g.audio.footstep_audit.is_empty(),"idle produces no footsteps")
 phase="walk";Input.action_press("move_forward");await create_timer(7).timeout
 phase="run";Input.action_press("sprint");await create_timer(4).timeout;Input.action_release("sprint");Input.action_release("move_forward");await create_timer(.5).timeout
 var count=g.audio.footstep_audit.size();check(count>15,"walk and run produce genuine foot contact sounds")
 phase="stopped";await create_timer(2).timeout;check(g.audio.footstep_audit.size()==count,"stopping produces no new step sounds")
 phase="walk_before_pause";Input.action_press("move_forward");await create_timer(2).timeout;g.toggle_pause();count=g.audio.footstep_audit.size()
 phase="paused";await create_timer(2).timeout;check(g.audio.footstep_audit.size()==count,"pause during walking produces no new step sounds");check(g.audio.step_players.all(func(p):return not p.playing or p.stream_paused),"pause suspends every active snow footstep playback");g.toggle_pause();Input.action_release("move_forward");await create_timer(.5).timeout;count=g.audio.footstep_audit.size()
 phase="dialogue_locked";g.player.locked=true;await create_timer(2).timeout;check(g.audio.footstep_audit.size()==count,"locked dialogue produces no foot sounds")
 check(not rows.any(func(x):return x.generic_loop_playing or x.generic_bus_playing),"legacy tap and looping footstep players remain silent")
 var max_gap=0.0;var alternating=true
 for i in rows.size():
  max_gap=maxf(max_gap,rows[i].sole_gap)
  # A fresh walk after stopping may legitimately start on the previous side.
  if i>0 and rows[i].phase==rows[i-1].phase and rows[i].side==rows[i-1].side:alternating=false
 check(max_gap<.025,"audible foot is touching snow within 2.5cm at playback; gap="+str(max_gap))
 check(alternating,"audible left and right contacts alternate")
 var folder=ProjectSettings.globalize_path("res://test_evidence/v415");DirAccess.make_dir_recursive_absolute(folder);var f=FileAccess.open(folder+"/foot_sync.json",FileAccess.WRITE);f.store_string(JSON.stringify({"failures":failures,"fixture":true,"rows":rows,"max_sole_gap":max_gap},"\t"));f.close()
 print("FOOT_SYNC failures=",failures," events=",rows.size())
 g.main_menu();g.queue_free();await process_frame;quit(1 if failures else 0)
