extends SceneTree
var g
var stalled:=0.0
func _initialize():call_deferred("run")
func run():
 g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g)
func _process(delta):
 if not is_instance_valid(g) or not g.get("built"):return false
 var a=g.young
 if a.moving and a.desired_speed>.5 and a.actual_speed<.03:stalled+=delta
 else:stalled=0
 if stalled>2:
  stalled=0;print("LIVE_STALL ",g.elapsed," position=",a.position," rootvelocity=",a.velocity," command=",a.horizontal_velocity," safe=",a.safe_velocity," target=",a.route[a.route_index]," agenttarget=",a.avoidance.target_position," navfinished=",a.avoidance.is_navigation_finished()," agentpos=",a.avoidance.global_position," player=",g.player.position)
  for i in a.get_slide_collision_count():
   var c=a.get_slide_collision(i);print("LIVE_COLLISION ",c.get_normal()," ",c.get_collider().get_parent().name," point=",c.get_position())
 return false
