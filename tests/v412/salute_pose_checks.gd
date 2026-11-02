extends SceneTree
# Pose fixture: compares evaluated bones after real animation frames, not a full playthrough.
var errors:=0
func _initialize():call_deferred("run")
func run():
 var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v412_salute_pose_fixture.json";g.begin();g.flags.intro_done=true;g.stage="SALUTE";g.hud.center_title.text=""
 g.player.restore(g.world.MEMORIAL+Vector3(1.2,.03,-1.7));g.quartermaster.position=g.world.MEMORIAL;g.quartermaster.pose_name="seated"
 var people=[g.director.commander,g.director.guard]+g.actors();var i=0
 for a in people:
  if a==g.quartermaster:continue
  a.moving=false;a.position=g.world.MEMORIAL+Vector3(-2.5+i*.60,.02,-2.8-float(i%2)*.5);i+=1
 g.interact();await create_timer(4.5).timeout
 for a in [g.player]+people:
  if a==g.quartermaster:continue
  var v=a.visual;var s=v.skeleton;var hand=v.to_local(s.to_global(s.get_bone_global_pose(s.find_bone("hand_r")).origin));var head=v.to_local(s.to_global(s.get_bone_global_pose(s.find_bone("Head")).origin))
  var ok=hand.y>1.30 and hand.distance_to(head)<.50
  print(("PASS " if ok else "FAIL ")+str(a.name)+" evaluated salute hand near temple: "+str(hand)+" head "+str(head)+" clock="+str(v.narrative_clock)+" pose="+v.narrative_pose)
  if not ok:errors+=1
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false);root.get_texture().get_image().save_png("res://test_evidence/v412/05_salute_pose_verified.png")
 g.main_menu();g.queue_free();await process_frame;quit(1 if errors else 0)
