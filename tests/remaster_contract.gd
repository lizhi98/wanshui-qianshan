extends SceneTree
var errors := 0
func _initialize(): call_deferred("run")
func check(value: bool, description: String):
	print(("PASS: " if value else "FAIL: ")+description)
	if not value: errors+=1
func run():
	for name in ["linchuan","amu","zhou"]:
		check(FileAccess.file_exists("res://assets/remaster/characters/"+name+".glb"),name+" new human exported")
	check(FileAccess.file_exists("res://game/remaster/dialogue.gd"),"interactive dialogue implemented")
	check(FileAccess.file_exists("res://game/remaster/campaign.gd"),"connected campaign implemented")
	if errors:
		quit(1)
		return
	var game = load("res://game/remaster/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.8).timeout
	check(game.player.visual.skeleton.get_bone_count()>40,"natural human skeleton")
	check(game.player.visual.animation_tree.active,"AnimationTree active")
	check(not "Superhero" in game.player.visual.rig.scene_file_path,"delivery uses new MPFB mesh")
	check(game.dialogue != null,"dialogue controller connected")
	game.begin(true)
	game.player.visual.speed=4.8
	game.player.movement_velocity=Vector3(0,0,4.8)
	game.dialogue.start("prologue")
	await create_timer(.5).timeout
	check(game.player.visual.speed==0.0,"running listener stops locomotion in dialogue")
	check(game.player.movement_velocity==Vector3.ZERO,"dialogue clears movement remaining from the approach")
	game.main_menu()
	check(not game.dialogue.active and not game.dialogue_locked,"return to title cancels the current conversation")
	check(game.player.visual.conversation_role==0 and game.amu.visual.conversation_role==0 and game.zhou.visual.conversation_role==0,"return to title clears conversation poses")
	check(not game.hud.dialogue_panel.visible,"return to title hides the dialogue panel")
	game.dialogue.close(true)
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(1 if errors else 0)
