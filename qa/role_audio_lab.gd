extends Node
# Explicitly staged verification fixture; not a full normal-input playthrough.
var g
var errors:=0
var folder:=""
var observed:Dictionary={}
func check(ok:bool,label:String):
 print(("PASS " if ok else "FAIL ")+label)
 if not ok:errors+=1
func shot(label):
 if DisplayServer.get_name()=="headless":return
 await get_tree().process_frame;await RenderingServer.frame_post_draw
 get_tree().root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func _process(_delta):
 if not g or g.action!="reveal" or not g.audio.voice_busy:return
 var who=str(g.audio.last_voice.get("who",""));var key=str(g.audio.last_voice.get("key",""))
 if observed.has(key):return
 var a=g.actor_by_name(who)
 check(a!=null and a.visual.voice_active,"speech is bound to its named actor: "+who)
 var active=0
 for actor in [g.player]+g.actors()+[g.director.commander,g.director.guard]:
  if actor.visual.voice_active:active+=1
 check(active==1,"exactly one actor speaks: "+who)
 observed[key]=who
 if who=="警卫员" and g.director.phase==6:call_deferred("guard_frame")
func guard_frame():
 await get_tree().create_timer(1.3).timeout
 check(g.director.camera_key=="警卫员答话","identity reply camera belongs to the guard")
 check(g.director.commander.pose_name=="witness","commander listens during the guard reply")
 await shot("03_guard_identity_reply")
func run(game):
 g=game;folder=ProjectSettings.globalize_path("user://verification/role_audio_v414");DirAccess.make_dir_recursive_absolute(folder)
 g.save_store.path="user://role_audio_v414_fixture.json";g.begin();g.flags.intro_done=true;g.set_process(false);g.player.locked=false;g.audio.clear_voice();g.audio.music_volume=0;g.audio.wind.stop()
 g.hud.center_title.text=""
 for a in g.actors()+[g.director.commander,g.director.guard]:a.moving=false;a.hide()
 for action in InputMap.get_actions():InputMap.action_erase_events(action)
 g.view.cinematic=false;g.view.set_process_input(false);g.view.camera_rotation=Vector3(-15,0,0)
 Input.action_press("move_forward");await get_tree().create_timer(8).timeout;Input.action_press("sprint");await get_tree().create_timer(3).timeout;Input.action_release("sprint");Input.action_release("move_forward");await get_tree().create_timer(1).timeout
 check(g.audio.footstep_audit.size()>8,"real foot plants play snow recordings while walking and running")
 var count=g.audio.footstep_audit.size();await get_tree().create_timer(2).timeout
 check(g.audio.footstep_audit.size()==count,"standing still produces no extra footsteps")
 await shot("01_snow_walk")
 g.player.locked=true;g.player.restore(g.world.MEMORIAL+Vector3(0,.02,-4));g.player.locked=true;g.stage="DISCOVERY";g.flags.march_started=true
 for i in g.actors().size():
  var a=g.actors()[i];a.show();a.moving=false;a.position=g.world.MEMORIAL+Vector3(-3.8+i*1.05,0,-3.7);a.position.y=g.world.height_at(a.position)+.01;a.pose_name="witness"
 g.quartermaster.position=g.world.MEMORIAL;g.quartermaster.pose_name="seated"
 var d=g.director;d.marching=true;d.reported=true;d.guard_summoned=true
 for i in 2:
  var a=d.commander if i==0 else d.guard;a.show();a.moving=false;a.position=g.world.MEMORIAL+Vector3(-1.1 if i==0 else 1.3,.01,-1.7);a.pose_name="witness"
 check(d.commander!=d.guard and g.actor_by_name("指挥员")==d.commander and g.actor_by_name("警卫员")==d.guard,"commander and guard are distinct bound actors")
 g.audio.music_volume=.65;g.audio.wind.play();g.action="reveal";g.action_clock=0;d.start();g.set_process(true)
 var clock=0.0
 while g.stage!="SALUTE" and clock<150:
  await get_tree().create_timer(.1).timeout;clock+=.1
  if d.phase==1 and not observed.has("order_photo"):observed.order_photo=true;await shot("02_commander_order")
 check(g.stage=="SALUTE","complete original climax reaches the salute prompt")
 var f=FileAccess.open(folder.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"fixture":true,"binary":OS.get_executable_path(),"failures":errors,"speakers":d.speaker_audit,"footsteps":g.audio.footstep_audit,"observed":observed},"\t"));f.close()
 print("ROLE_AUDIO_LAB failures=",errors)
 g.main_menu();g.queue_free();await get_tree().process_frame;get_tree().quit(1 if errors else 0)
