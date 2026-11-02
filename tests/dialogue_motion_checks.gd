extends SceneTree
var errors:=0
var actors:Array=[]
var visuals:Array=[]
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func hands(visual)->PackedVector3Array:
	var sk=visual.skeleton
	var height=sk.get_bone_global_rest(sk.find_bone("Head")).origin.y
	return PackedVector3Array([sk.get_bone_global_pose(sk.find_bone("hand_r")).origin/height,sk.get_bone_global_pose(sk.find_bone("hand_l")).origin/height])
func difference(a,b)->float: return a[0].distance_to(b[0])+a[1].distance_to(b[1])
func run():
	for label in ["Linchuan","Amu","Zhou"]:
		var actor=Node3D.new()
		actor.name=label
		root.add_child(actor)
		var visual=load("res://game/remaster/character_visual.gd").new()
		actor.add_child(visual)
		actors.append(actor); visuals.append(visual)
		visual.mode="talk"
		visual.gesture="talk"
		if visual.has_method("set_conversation"): visual.set_conversation(true,"talk",0)
	await create_timer(1.2).timeout
	var poses=visuals.map(hands)
	for i in 3:
		var j=(i+1)%3
		var distance=difference(poses[i],poses[j])
		check(distance>.065,"different speaking body language: %s / %s = %.3f"%[actors[i].name,actors[j].name,distance])
	var has_roles=visuals[0].has_method("set_conversation")
	check(has_roles,"conversation supports separate speaker and listener roles")
	if has_roles:
		var before=hands(visuals[2])
		visuals[2].set_conversation(true,"point",3)
		await create_timer(1.2).timeout
		check(difference(before,hands(visuals[2]))>.08,"pointing differs visibly from ordinary speech")
		for visual in visuals: visual.set_conversation(false,"talk",4)
		await create_timer(.8).timeout
		for visual in visuals: check(visual.mode=="idle","listener uses restrained body language")
	for actor in actors: actor.queue_free()
	await process_frame
	quit(1 if errors else 0)
