extends SceneTree
# Audit the constructed runtime graph, including every action and locomotion clip.
var failures:=0
var clips:=0
func _initialize():call_deferred("run")
func scan(node,animator,path:String):
 if node is AnimationNodeAnimation:
  clips+=1
  if not animator.has_animation(node.animation):
   failures+=1;print("FAIL missing animation ",path," -> ",node.animation)
 elif node is AnimationNodeBlendTree or node is AnimationNodeStateMachine:
  for key in node.get_node_list():scan(node.get_node(key),animator,path+"/"+str(key))
 elif node is AnimationNodeBlendSpace1D:
  for i in node.get_blend_point_count():scan(node.get_blend_point_node(i),animator,path+"/"+str(i))
func run():
 var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.5).timeout
 var people=[g.player]+g.actors()+[g.director.commander,g.director.guard]
 for actor in people:
  var before=failures;scan(actor.visual.animation_tree.tree_root,actor.visual.animator,str(actor.name))
  if failures==before:print("PASS ",actor.name," all animation bindings exist")
 print("BINDING_AUDIT actors=",people.size()," clips=",clips," missing=",failures)
 g.main_menu();g.queue_free();await process_frame;quit(1 if failures else 0)
