extends SceneTree
## Deliberately arranged regression fixtures, never evidence of full playthrough.
var errors:=0
func _initialize(): call_deferred("run")
func check(value:bool,label:String):
	print(("PASS " if value else "FAIL ")+label)
	if not value: errors+=1
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate(); root.add_child(g)
	await process_frame
	g.store.path="user://golden_hook_presentation_test.json"; g.begin_chapter(true)
	g.story.step="first_fishing"; g.story.inventory.hook=1; g.story.hook_form=4
	g.fishing.enter(0); g.fishing.model.state=g.fishing.Model.State.CAUGHT; g.fishing.catch_animation=1.99
	g.fishing.tick(.04)
	check(not g.hud.fishing_panel.visible,"automatic catch exit cannot reopen the fishing panel over subtitles")
	g._cancel_dialogue(); g.busy=false; g.player.locked=true
	g.story.step="secret"; g.elder.moving=false; g.elder.position=g.world.points.secret
	await create_timer(.3).timeout
	check(g.elder.visual.posture=="seated" and g.elder.visual.held=="scraps","the secret has a seated elder and actual roots and bones in his bowl")
	g.player.visual.posture="kneel"; g.player.visual.hold("bowl")
	await create_timer(3.5).timeout
	var sk=g.player.visual.skeleton
	var pelvis=sk.get_bone_global_pose(sk.find_bone("pelvis")).origin
	check(pelvis.y<.72,"a held bowl cannot blend kneeling back into standing after the work clip ends")
	check(not g.player.visual.rifle.visible,"chapter poses never expose an inherited combat rifle")
	var actual_hook=g.world.work_hook
	g.player.visual.hold("parcel"); actual_hook.reparent(g.player.visual.held_node,false)
	g.begin_chapter(true); await process_frame; await process_frame
	check(is_instance_valid(actual_hook) and g.world.work_hook==actual_hook,"restarting protects the unique hook while a parcel animation is interrupted")
	check(is_instance_valid(actual_hook) and actual_hook.get_parent()==g.world.items.needle,"the same needle returns to its cloth tool pouch for a new chapter")
	g.return_to_menu(); g.queue_free(); await process_frame; await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_presentation_test.json"))
	quit(1 if errors else 0)
