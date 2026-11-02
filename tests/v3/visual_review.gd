extends SceneTree
var game
func _initialize(): call_deferred("run")
func shot(name_value:String):
	await process_frame; await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://test_evidence/v3/"+name_value+".png")
func run():
	DirAccess.make_dir_recursive_absolute("res://test_evidence/v3")
	game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	game.save_store.path="user://v3_preview_only.json"
	await create_timer(.5).timeout; game.begin(); await create_timer(.5).timeout
	await shot("01_compact_approach")
	game._apply_snapshot({"version":3,"ledger":{"current":"repair","done":{"march":true,"recon":true,"escort":true}},"modules":{"repair":{"site":0,"step":"select","repaired":[false,false]}},"position":[-.6,.1,-3.4],"elapsed":0,"retries":0,"choice":0})
	game.view.camera_rotation=Vector3(-16,-8,0)
	await create_timer(7).timeout; await shot("02_bridge_under_fire")
	print("CAM player=",game.player.position," view=",game.view.global_position," camera=",game.view.camera.global_position," local=",game.view.camera.position)
	var camera_clear=game.view.camera.position.z<4
	print("PASS roof avoidance" if camera_clear else "FAIL roof avoidance")
	var q=PhysicsRayQueryParameters3D.create(game.view.global_position,game.view.camera.global_position,1); q.hit_back_faces=true
	print("CAM ray=",game.view.get_world_3d().direct_space_state.intersect_ray(q))
	for mesh in game.world.find_children("*","MeshInstance3D",true,false):
		var aabb=mesh.get_aabb().grow(.1)
		var hit=aabb.intersects_segment(mesh.to_local(game.view.camera.global_position),mesh.to_local(game.player.position+Vector3(0,1.2,0)))
		if hit!=null: print("CAM MESH ",mesh.get_path()," pos=",mesh.global_position," bounds=",aabb)
	var before=game.hud.guide_panel.get_rect().get_area()/game.hud.root_control.size.x/game.hud.root_control.size.y
	print("GUIDE OCCUPANCY ",before," target_card_visible=",game.hud.target_panel.visible)
	game.view.set_physics_process(false)
	game.view.camera.position=Vector3(.2,.2,.5)
	game.view._fade_occluding_allies(1)
	await shot("03_camera_close_fade")
	var faded=true
	for mesh in game.player.visual.find_children("*","MeshInstance3D",true,false):
		if (mesh.layers&game.view.camera.cull_mask)!=0: faded=false
	print("PASS close camera hides player" if faded else "FAIL close camera hides player")
	for node in game.find_children("*","AudioStreamPlayer",true,false): node.stop(); node.stream=null
	game.assault.stop(); game.queue_free(); await process_frame; quit(0 if camera_clear and faded else 1)
