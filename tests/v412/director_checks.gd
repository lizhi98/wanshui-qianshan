extends SceneTree
# Explicit state/time fixtures, NOT the continuous input playthrough.
var g
var failures:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:failures+=1
func run():
	g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout
	g.save_store.path="user://v412_director_fixture.json";g.begin();g.flags.intro_done=true;g.paused=true
	var d=g.director
	check(d.commander!=g.zhou and d.guard!=g.amu,"commander and guard are independent physical actors")
	check(d.commander.visual.skeleton.get_bone_count()==53,"commander uses the full human skeleton")
	check(d.lines.size()==10 and d.lines[4].text=="把军需处长给我叫来！","selected B script contains the required order")
	check(g.world.find_children("DetailedRockTrailCollision","Node3D",true,false).is_empty(),"folded secondary road collider is absent")
	check(g.END_INDEX==12,"ending requires only the short return to landmark 12")
	g.save_checkpoint();check(not g.save_store.read().is_empty(),"new-version checkpoints survive JSON number decoding")
	var snapshot=d.snapshot();check(g.save_store.valid_director(snapshot),"director checkpoint is structurally valid")
	var bad=snapshot.duplicate(true);bad.phase=999;check(not g.save_store.valid_director(bad),"unknown dramatic phase is rejected")
	bad=snapshot.duplicate(true);bad.commander.position=[NAN,0,0];check(not g.save_store.valid_director(bad),"invalid commander coordinates are rejected")
	g.action="reveal";g.stage="DISCOVERY";d.start();g.audio.clear_voice();g.audio.voice_busy=true;d.tick(20)
	check(d.phase==0,"dramatic beat cannot advance over a playing line")
	g.audio.voice_busy=false
	for phase in 9:
		g.audio.clear_voice();d.tick(d.MINIMUM[phase]+.1)
		if phase==5:check(d.music_cut,"identity beat requests music silence")
	check(d.audit.size()==9 and d.audit[1].phase=="怒问" and d.audit[7].phase=="震惊","anger, unanswered order, identity and shock occur in order")
	check(g.stage=="SALUTE" and g.action=="" and g.player.locked,"the climax hands control to one deliberate salute prompt")
	g.interact();check(g.action=="salute" and not d.music_cut,"one E begins the salute and allows the solemn music fade")
	g._action_tick(10)
	check(g.stage=="CONTINUE" and not g.player.locked,"the salute restores movement without a score")
	check(d.commander.moving and d.guard.moving,"commander and guard physically rejoin the march")
	check(d.commander.route.size()==2,"commander departure uses a short real path")
	g.main_menu();g.audio.clear_voice();g.queue_free();await process_frame;quit(1 if failures else 0)
