extends SceneTree
class Walker extends CharacterBody3D:
 var tangent:=false
 var goals=[]
 var index:=0
 var speed_y:=0.0
 func _ready():
  collision_layer=8;collision_mask=1;floor_snap_length=.5;floor_max_angle=deg_to_rad(49)
  var c=CollisionShape3D.new();var s=CapsuleShape3D.new();s.height=1.74;s.radius=.29;c.shape=s;c.position.y=.87;add_child(c)
 func _physics_process(delta):
  var d:Vector3=goals[index]-position;d.y=0
  if d.length()<.16 and index<goals.size()-1:index+=1;d=goals[index]-position;d.y=0
  var h=d.normalized()*1.85 if d.length()>.16 else Vector3.ZERO
  if is_on_floor():speed_y=-.5
  else:speed_y-=25*delta
  velocity=h+Vector3.UP*speed_y
  if tangent and is_on_floor() and h.length()>.1:
   var n=get_floor_normal();velocity.y=-(h.x*n.x+h.z*n.z)/maxf(.65,n.y)
  apply_floor_snap();move_and_slide()
func _initialize():call_deferred("run")
func run():
 var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.paused=true;var rows=[]
 var direction=g.world.route.POINTS[7]-g.world.route.POINTS[6];direction.y=0;direction=direction.normalized();var side=direction.cross(Vector3.UP)
 for i in range(-20,21):
  for variant in [false,true]:
   var a=Walker.new();a.tangent=variant;var p=g.world.route.POINTS[6]+side*float(i)*.04;p.y=g.world.height_at(p)+.02;a.position=p;a.goals=[g.world.route.POINTS[7]+side*float(i)*.04,g.world.route.POINTS[8]+side*float(i)*.04];root.add_child(a);rows.append(a)
 await create_timer(35).timeout
 for variant in [false,true]:
  var stuck=0
  for a in rows:
   if a.tangent==variant:
    if a.index==0:stuck+=1;print("SOLVER_STUCK ",variant," ",a.position," velocity=",a.velocity," normal=",a.get_floor_normal())
  print("SOLVER_RESULT tangent=",variant," stalled_before_bend=",stuck," total=41")
 for a in rows:a.queue_free()
 g.queue_free();await process_frame;quit()
