extends SceneTree
# Explicit 720p performance fixtures, not the continuous playthrough.
var g
var ticks:Array=[]
var active:=false
var previous:=0
var sites:Array=[]
func _initialize():call_deferred("run")
func _process(_delta):
 var now=Time.get_ticks_usec()
 if active and previous>0:ticks.append(float(now-previous)/1000.0)
 previous=now
 return false
func run():
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.5).timeout;g.save_store.path="user://v412_benchmark_fixture.json";g.begin();g.flags.intro_done=true;g.hud.center_title.text="";g.player.locked=true
 var points=[Vector3(0,0,37),g.world.route.POINTS[8],g.world.MEMORIAL]
 var stages=["CAMP","STORM","DISCOVERY"]
 for j in 3:
  var point=points[j];g.stage=stages[j];g.player.restore(point+Vector3.UP*.01);g.player.locked=true
  var people=g.actors()+[g.director.commander,g.director.guard]
  for i in people.size():
   var a=people[i];a.position=point+Vector3((i%2)*1.2-.6,0,float(i/2)*1.2+2);a.position.y=g.world.height_at(a.position)+.01;a.moving=false;a.pose_name=""
  g.view.cinematic=true;g.view.camera.global_position=point+Vector3(4,5.2,11);g.view.camera.look_at(point+Vector3(0,1,-12))
  await create_timer(1.5).timeout;ticks=[];previous=0;active=true;await create_timer(4).timeout;active=false;ticks.sort()
  var mean=0.0
  for t in ticks:mean+=t
  mean/=maxi(1,ticks.size());sites.append({"stage":stages[j],"frames":ticks.size(),"median_frame_ms":ticks[int(ticks.size()*.5)],"p95_frame_ms":ticks[int(ticks.size()*.95)],"mean_fps":1000/maxf(.001,mean)})
 var folder="res://test_evidence/v412";DirAccess.make_dir_recursive_absolute(folder);var f=FileAccess.open(folder+"/realtime_benchmark.json",FileAccess.WRITE);f.store_string(JSON.stringify({"resolution":str(root.size),"sites":sites,"configured_near":10,"configured_mid":24,"configured_far":48,"peak_in_frustum":g.crowd.peak_in_frame},"\t"));f.close();print("RENDER_BENCHMARK ",sites)
 g.main_menu();g.audio.clear_voice();g.queue_free();await process_frame;quit()
