extends SceneTree
var g
var errors:=0
func _initialize():call_deferred("run")
func check(ok,label):
 print(("PASS " if ok else "FAIL ")+label)
 if not ok:errors+=1
func run():
 g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v415_checks.json";g.begin();g.flags.intro_done=true;g.set_process(false);g.set_physics_process(false);g.audio.clear_voice()
 var d=g.director
 check(d.commander.visual.personality==0 and d.guard.visual.personality==1 and g.quartermaster.visual.personality==2,"commander, guard and quartermaster use three distinct character models")
 g.quartermaster.pose_name="seated";g.quartermaster.visual.pose("seated");g.audio._set_speaker("老战士",true)
 check(not g.quartermaster.visual.voice_active,"deceased quartermaster refuses speaking flag")
 var count=g.audio.voice_queue.size();g.say("老战士","这句话不得在牺牲后播放")
 check(g.audio.voice_queue.size()==count,"deceased quartermaster cannot enqueue new speech")
 g.audio.voice_queue.append({"who":"老战士","text":"旧队列也必须跳过","key":"stale"});g.audio._next_voice()
 check(g.audio.voice_queue.is_empty() and not g.audio.voice_busy,"queued stale quartermaster speech is rejected")
 var rock=g.world.get_node_or_null("Bend7ClearanceRock")
 check(rock!=null,"blocking bend-7 rock has a stable identity")
 if rock:
  check(rock.find_children("*","StaticBody3D",true,false).any(func(b):return b.collision_layer==1),"visible relocated boulder retains real collision")
 g.stage="STORM";g.flags.at_pass=true;g.player.restore(g.world.route.POINTS[12]);g.player.locked=true;g.crowd.set_physics_process(false)
 for i in g.actors().size():
  var a=g.actors()[i];a.restore();a.pose_name="";a.moving=false
  if a==g.quartermaster:a.position=Vector3(50,0,40);continue
  a.position=g._party_path(1,6,i)[-1]+Vector3.UP*.02;a.rotation.y=atan2(-10.5,-14.0)
 await create_timer(2).timeout;g._group_walk(7,8);await create_timer(45).timeout
 for a in g.actors():
  if a!=g.quartermaster:check(a.route_index>=2,"crowded squad passes the formerly blocked bend: "+str(a.name))
 g.main_menu();g.queue_free();await process_frame;quit(1 if errors else 0)
