extends SceneTree
# Transaction, save and input-lock fixtures; full acceptance is memorial_replay.gd.
var errors:=0
var g
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func advance(seconds:float):g._action_tick(seconds)
func run():
	g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.3).timeout;g.save_store.path="user://v41_story_fixture.json"
	if "--restore-fixture" in OS.get_cmdline_user_args():
		check(g.continue_story(),"new process reads the V4.1 checkpoint")
		check(g.stage=="CONTINUE" and g.flags.get("honored",false),"new process retains narrative progress")
		check(g.young.visual.coat_received and g.quartermaster.pose_name=="seated","new process retains coats and the seated old soldier")
		check(g.crowd.units.size()==72,"new process rebuilds the layered column")
		await cleanup();return
	g.begin();g.flags.intro_done=true;g.hud.center_title.text="";g.player.locked=false;g._reset_camera()
	check(g.actors().size()==8 and g.actors().all(func(a):return a.visual.skeleton.get_bone_count()==53),"eight near NPCs retain the existing 53-bone characters")
	check(g.crowd.mid_count==24 and g.crowd.far_count==48 and g.crowd.batches.size()==8,"mid and far columns use the configured low-cost tiers")
	check(g.crowd.find_children("*","CharacterBody3D",true,false).is_empty(),"background column does not enable dozens of physics characters")
	check(not "军需处长" in g.instruction().title and not "牺牲" in g.instruction().action,"camp objectives do not reveal the old soldier's identity")
	var qm_id=g.quartermaster.get_instance_id()
	g.player.restore(g.world.CRATE+Vector3(0,.1,1.7));g.interact();check(g.action=="","parcel pickup requires inspecting the remaining stock first")
	g.flags.stock_seen=true;g.interact();check(g.action=="take" and g.player.locked,"pickup uses its own locked animation state")
	advance(.5);g.toggle_pause();var saved=g.save_store.read();check(saved.action=="take" and saved.action_clock>.4,"mid-action checkpoint stores the pending transaction")
	g.toggle_pause();check(g.player.locked,"unpausing a pending action does not release movement")
	g.restore_checkpoint(saved);check(g.player.locked and g.player.visual.narrative_pose=="take","loading the pickup restores the correct action pose and lock")
	advance(3);check(g.stock==2 and g.player.carrying and g.parcel.visible,"completed pickup removes exactly one parcel and shows it in the hands")
	# Reposition the fixture without calling player.restore(), which correctly
	# resets carrying as part of a fresh player reset.
	g.player.position=g.young.position+Vector3(0,.1,1.6);g.player.velocity=Vector3.ZERO;g.interact();check(g.action=="give" and not g.young.visual.coat_received,"coat appearance changes after the handover rather than on approach")
	advance(5);check(g.young.visual.coat_received and g.stats.delivered==1 and not g.player.carrying,"handover commits inventory and the recipient's clothing together")
	g.player.restore(g.young.position+Vector3(0,.1,1.6));g.interact();check(g.action=="" and g.stats.delivered==1,"an empty-handed repeated interaction cannot duplicate a delivery")
	g.stage="SEARCH";g.player.restore(g.world.MEMORIAL+Vector3(0,.1,-1.6));g.interact();check(g.action=="" and not g.flags.get("identity_revealed",false),"the reveal cannot be triggered from the search stage")
	g.stage="DISCOVERY";check(not g.can_observe("ledger"),"the record cannot be read before checking the person and clothing")
	g.stage="SALUTE";g.flags.identity_revealed=true;g.interact();check(g.action=="salute" and g.player.locked,"salute uses one deliberate action without a reaction-speed test")
	advance(4);check(g.player.visual.narrative_pose=="salute","the salute remains active through its hold")
	advance(6);check(g.flags.get("honored",false) and g.stage=="CONTINUE","the full salute unlocks continued marching")
	check(g.quartermaster.get_instance_id()==qm_id,"the familiar old soldier remains the same entity throughout the story")
	g.action="";g.player.carrying=false;g.parcel.hide();g.stock=0;g.stats.delivered=3;g.young.visual.set_coat(true);g.amu.visual.set_coat(true);g.quartermaster.pose_name="seated"
	g.flags={"intro_done":true,"march_started":true,"obstacle_cleared":true,"storm_signal":true,"strap_found":true,"inspected":true,"coat_seen":true,"ledger_found":true,"identity_revealed":true,"honored":true,"at_pass":true,"complete":true}
	for stage in g.save_store.ACTS:
		g.stage=stage;g.safe_point=g.world.MEMORIAL+Vector3(0,.2,-1.6);g.save_checkpoint();var data=g.save_store.read()
		check(not data.is_empty() and data.stage==stage,"narrative checkpoint round trip: "+stage)
		g.restore_checkpoint(data);check(g.stage==stage and g.actors().size()==8,"live narrative state restoration: "+stage)
	g.stage="CONTINUE";g.flags.erase("at_pass");g.flags.erase("complete");g.save_checkpoint();var original=FileAccess.get_file_as_string(g.save_store.path);var invalid=g.last_checkpoint.duplicate(true);invalid.stock=4
	check(not g.save_store.write(invalid) and FileAccess.get_file_as_string(g.save_store.path)==original,"invalid inventory cannot replace the good checkpoint")
	var bad=g.last_checkpoint.duplicate(true);bad.flags.erase("honored");check(not g.save_store.valid(bad),"advanced narrative stages require the preceding story action")
	var positions=g.crowd.units.map(func(u):return float(u.s));g.crowd.units[0].s=500;g.crowd.restore_state(g.crowd.clock,positions);check(absf(g.crowd.units[0].s-positions[0])<.001,"crowd restoration preserves individual queue positions")
	var retries=g.retries;g.fail("fixture fall");g.retry_checkpoint();check(not g.failed and g.retries==retries+1 and g.quartermaster.pose_name=="seated","failure retry restores people, story and attempt count")
	g.stage="DISCOVERY";g.player.restore(g.quartermaster.position+Vector3(0,.1,-1.5));g.audio.clear_voice();g.audio.music_gain=.1
	for i in 60:g.audio._process(.1)
	check(g.audio.music_silent and g.audio.music_gain<.001 and g.audio.wind.playing,"reveal music fades out while environmental wind remains audible")
	check(g.audio.players.size()==2,"retries retain the same bounded crossfade pair")
	g.stage="CONTINUE";g.outro_active=true;g.outro_clock=10;g._physics_process(.016);check(g.outro_clock==10,"physics does not restart the ending timer while the pullback is active");g.outro_active=false
	g.stage="CONTINUE";g.safe_point=g.world.MEMORIAL+Vector3(0,.2,-1.6);g.save_checkpoint()
	await cleanup()
func cleanup():
	g.main_menu();g.audio.clear_voice();g.queue_free();await process_frame;await create_timer(.2).timeout;quit(1 if errors else 0)
