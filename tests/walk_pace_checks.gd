extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func run():
 for scene in ["res://game/v2/main.tscn","res://game/memorial/main.tscn","res://game/golden_hook/main.tscn"]:
  var g=load(scene).instantiate();root.add_child(g);await process_frame
  g.set_process(false);g.set_physics_process(false);g.paused=false
  var p=g.player;var v=p.visual
  p.set_physics_process(false);v.set_process(false);p.locked=false;p.carrying=false;p.aiming=false
  if g.get("weather"):g.weather.exposure=0
  Input.action_press("move_forward")
  p.walking_speed_scale=1;p.handle_controls(1.0/60);var before=p.movement_velocity
  p.walking_speed_scale=1.25;p.handle_controls(1.0/60);var after=p.movement_velocity
  var wind=g.weather.force_at(p.position) if g.get("weather") else Vector3.ZERO
  var ratio=(after-wind).length()/(before-wind).length()
  check(absf(ratio-1.25)<.002,"walking speed +25%: "+scene+" ratio="+str(ratio))
  Input.action_press("sprint");p.handle_controls(1.0/60);var sprint=p.movement_velocity
  p.walking_speed_scale=1;p.handle_controls(1.0/60)
  check(sprint.distance_to(p.movement_velocity)<.001,"sprint speed unchanged")
  p.walking_speed_scale=1.25;Input.action_release("sprint")
  p.velocity=after;p.handle_effects(1.0/60)
  v.mode="walk";v.speed=(after-wind).length();v.animation_offset=0
  for i in 60:v._process(1.0/60)
  check(is_equal_approx(v.animation_tree.get("parameters/WalkPace/scale"),1.25),"locomotion tempo matches speed increase")
  check(absf(v.motion_speed-v.speed/1.25)<.02,"original stride blend retained")
  p.aiming=true;check(p.walk_speed_multiplier()==1,"aiming not accelerated")
  p.aiming=false;p.carrying=true;check(p.walk_speed_multiplier()==1,"carrying not accelerated")
  p.carrying=false;Input.action_release("move_forward")
  p.velocity=Vector3.ZERO;p.handle_effects(1.0/60)
  check(v.walk_gait_scale==1,"idle returns to normal tempo")
  if scene.contains("golden_hook"):
   g.story.step="leave";check(p.walk_speed_multiplier()==1,"chapter ending walk unchanged")
  g.queue_free();await process_frame;await create_timer(.3).timeout
 print("WALK_PACE_CHECK failures=",failures);quit(1 if failures else 0)
