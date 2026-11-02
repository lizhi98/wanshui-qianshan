extends SceneTree
var errors=0
var game
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func run():
	game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	await create_timer(.3).timeout
	game.save_store.path="user://guide_checks_only.json"
	var ledger=game.ledger.ORDER
	for id in ["march","recon","escort","repair","traversal","relay"]:
		var done={}
		for i in ledger.find(id): done[ledger[i]]=true
		game._apply_snapshot({"version":3,"ledger":{"current":id,"done":done},"modules":{},"position":[0,.1,16],"elapsed":0,"retries":0,"choice":0})
		await process_frame
		var data=game.hud.guidance.data()
		check(not data.title.is_empty() and not data.action.is_empty() and not data.body.is_empty(),"chapter has concrete tutorial "+id)
		check(not data.target.is_empty(),"named target "+id)
	game._apply_snapshot({"version":3,"ledger":{"current":"repair","done":{"march":true,"recon":true,"escort":true}},"modules":{"repair":{"step":"pickup","material":"good","site":0}},"position":[2.3,.1,7.85],"elapsed":0,"retries":0,"choice":0})
	for step in ["select","preparing","position","tie","check","pickup","join","npc_ready","lifting","carry","parked","lowering","auto_secure","align","secure","place_check","recover"]:
		game.repair.step=step
		var data=game.hud.guidance.data()
		check(data.point!=Vector3.INF and not data.action.is_empty(),"repair substep has target and controls "+step)
	game.repair.step="pickup"
	game.view.camera_rotation.y=180
	await create_timer(.4).timeout
	check(not game.hud.target_panel.visible and game.hud.direction_panel.visible,"target behind camera uses a slim direction bar without covering actors")
	check("取板" in game.hud.direction_text.text or "路标" in game.hud.direction_text.text,"direction bar includes the target name")
	check(game.hud.guide_title.get_theme_font_size("font_size")==16,"compact tutorial uses a 16px title at 720p")
	check(game.hud.guide_panel.get_rect().get_area()/game.hud.root_control.size.x/game.hud.root_control.size.y<.05,"default guide occupies less than five percent of the screen")
	check(not game.hud.guide_body.visible,"details stay collapsed during ordinary play")
	Input.action_press("guide_detail"); await process_frame; await process_frame
	check(game.hud.guide_body.visible,"holding Tab reveals the full instructions")
	Input.action_release("guide_detail"); await process_frame
	check(game.hud.guide_panel.size.y>=game.hud.guide_panel.get_combined_minimum_size().y,"tutorial card fits content")
	check(not game.hud.modern_panel.visible and game.hud.modern_panel.get_child_count()==0,"retired reconstruction controls are not built into the player HUD")
	for node in game.find_children("*","AudioStreamPlayer",true,false): node.stop(); node.stream=null
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("GUIDANCE FAILURES ",errors); quit(1 if errors else 0)
