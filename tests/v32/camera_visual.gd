extends SceneTree
var game
var errors:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func shot(label:String):
	await process_frame; await process_frame; RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://test_evidence/v32/"+label+".png")
func run():
	DirAccess.make_dir_recursive_absolute("res://test_evidence/v32")
	game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	await create_timer(.5).timeout
	game.save_store.path="user://v32_camera_fixture.json"; game.view.set_process_input(false)
	game._apply_snapshot({"version":3,"ledger":{"current":"repair","done":{"march":true,"recon":true,"escort":true}},"modules":{},"position":[.25,.1,-3.1],"elapsed":0,"retries":0,"choice":0})
	game.view.camera_rotation=Vector3(-10,0,0)
	await create_timer(4).timeout; await shot("01_detailed_bridge_approach")
	game._apply_snapshot({"version":3,"ledger":{"current":"traversal","done":{"march":true,"recon":true,"escort":true,"repair":true}},"modules":{"repair":{"repaired":[true,true]}},"position":[1.43,.05,-54.35],"elapsed":0,"retries":0,"choice":0})
	Input.action_press("aim"); game.view.camera_rotation=Vector3(-8,0,0)
	await create_timer(1.5).timeout; await shot("02_right_chain_aim")
	print("CAMERA right edge ",game.view.camera.global_position," shoulder ",game.view.shoulder_side)
	check(game.view.shoulder_side<0 and absf(game.view.camera.global_position.x)<1.5,"right bridge edge moves the aiming camera to the clear inside shoulder")
	var query=PhysicsShapeQueryParameters3D.new(); query.shape=game.view.camera_shape; query.transform=Transform3D(Basis.IDENTITY,game.view.camera.global_position); query.collision_mask=game.view.CAMERA_MASK
	check(game.view.get_world_3d().direct_space_state.intersect_shape(query,8).is_empty(),"camera volume stays outside bridge rails and scenery")
	check(game.player.aiming,"the right-chain camera fixture uses the actual held aiming input")
	var blocker=StaticBody3D.new(); blocker.collision_layer=32; blocker.collision_mask=0; game.add_child(blocker)
	var shape=CollisionShape3D.new(); shape.shape=BoxShape3D.new(); shape.shape.size=Vector3(3,3,.3); blocker.add_child(shape)
	blocker.global_position=game.view.global_position+Vector3(0,0,1.2)
	await create_timer(.5).timeout
	check(game.view.camera.global_position.distance_to(game.view.global_position)<1.0,"a rear obstacle retracts the whole camera volume before it penetrates")
	blocker.queue_free(); await create_timer(1).timeout
	game.view.set_physics_process(false); game.amu.set_physics_process(false)
	var eye=game.view.camera.global_position
	game.amu.global_position=eye-game.view.camera.global_basis.z*.7-Vector3(0,1.1,0)
	game.view._fade_occluding_allies(.1)
	var hidden=true
	for mesh in game.amu.visual.find_children("*","MeshInstance3D",true,false):
		if (mesh.layers&game.view.camera.cull_mask)!=0: hidden=false
	check(hidden,"a close teammate is fully excluded from the camera instead of becoming a ghost face")
	await shot("03_teammate_does_not_cover_aim")
	game.amu.global_position+=Vector3(8,0,0); game.view._fade_occluding_allies(.5)
	var restored=true
	for mesh in game.amu.visual.find_children("*","MeshInstance3D",true,false):
		if mesh.layers!=int(mesh.get_meta("camera_original_layers")): restored=false
	check(restored,"teammate visibility returns after leaving the view")
	game.view.set_physics_process(true); Input.action_release("aim")
	game._apply_snapshot({"version":3,"ledger":{"current":"relay","done":{"march":true,"recon":true,"escort":true,"repair":true,"traversal":true}},"modules":{"repair":{"repaired":[true,true]}},"position":[0,.1,-74],"elapsed":0,"retries":0,"choice":0})
	game.view.camera_rotation=Vector3(-10,0,0)
	await create_timer(2).timeout; await shot("04_captured_bridgehead")
	check(game.enemies.all(func(actor):return actor.dead),"captured bridgehead contains no living main defenders")
	game.view.set_physics_process(false); game.view.global_position=Vector3(-13,2.7,4); game.view.rotation=Vector3.ZERO; game.view.camera.position=Vector3.ZERO; game.view.camera.look_at(Vector3(-9,1,10)); game.view.camera.fov=60
	await shot("05_cannon_and_environment_detail")
	game.main_menu(); game.audio.clear_voice()
	for node in game.find_children("*","AudioStreamPlayer",true,false): node.stop(); node.stream=null
	game.queue_free(); await process_frame; await create_timer(.2).timeout; quit(1 if errors else 0)
