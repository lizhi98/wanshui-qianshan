# State fixtures exercise restoration; input replay never uses these shortcuts.
extends SceneTree
var errors:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func fixture(id:String)->Dictionary:
	var order=load("res://game/v2/objectives.gd").ORDER
	var done={}
	for i in order.find(id): done[order[i]]=true
	var pos={"march":[0,.1,45],"recon":[0,.1,16],"escort":[1,.1,5],"repair":[2.3,.1,7.85],"traversal":[1.2,.05,-58.2],"relay":[1.05,.05,-75.4],"modern":[0,.1,-80.5],"complete":[0,.1,-80.5]}[id]
	var modules={"march":{"jumped":true,"supply":true},"recon":{"found":["firepoint","gap","cover"],"route":"B"},"escort":{"route":"B","leg":1,"blocker_cleared":true,"enemy_health":[0,66]},"repair":{"site":1,"step":"pickup","material":"cracked","repaired":[true,false],"rope_assist":true},"traversal":{"checkpoint":1,"fixed":true},"relay":{"observed":true,"clear":false,"angle":0},"modern":{"collected":[0,1,2],"classified":[0,1,2],"placed":[0,1,2],"compared":true,"selected":2}}
	if order.find(id)>order.find("repair"): modules.repair={"repaired":[true,true],"rope_assist":true}
	return {"version":3,"ledger":{"current":id,"done":done},"modules":modules,"position":pos,"elapsed":300.0,"retries":2,"choice":1}
func run():
	var game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	await create_timer(.5).timeout
	var read_only="--read-checkpoints" in OS.get_cmdline_user_args()
	for id in ["march","recon","escort","repair","traversal","relay","complete"]:
		game.save_store.path="user://v2_process_"+id+".json"
		if not read_only: check(game.save_store.write(fixture(id)),"write process fixture "+id)
		check(game.continue_story() and game.ledger.current==id,"restore chapter in "+("new process " if read_only else "process ")+id)
		check(not game.failed and game.player.health==100,"restored controls and health are valid "+id)
		if id=="escort":
			check(game.escort.leg==1 and game.enemies[0].dead and game.enemies[1].health==66,"escort cover and defeated enemy persist")
			game.player.damage(1000); check(game.failed,"combat damage reaches ordinary failure handling")
			game.retry_checkpoint()
			check(not game.failed and game.player.health==100 and game.escort.leg==1 and game.enemies[0].dead,"combat retry preserves the actual reached cover and defeated threat")
		if id=="repair":
			check(game.world.v2_repair_is_enabled(0) and not game.world.v2_repair_is_enabled(1),"repair restore retains only the finished gap")
			game.player.position=game.repair.pickup_position(); game.amu.position=game.repair._pickup_helper_goal(); game.repair.interact()
			await create_timer(1.5).timeout
			check(game.player.carrying,"fixture starts real held timber")
			game.toggle_pause(); check(game.player.locked,"pause blocks carrying movement"); game.toggle_pause()
			game.main_menu(); check(game.continue_story(),"title resumes interrupted carrying")
			check(not game.player.carrying and game.repair.step=="pickup" and game.repair.active_board.get_parent()==game.repair,"interrupted carry restores one safe timber owner")
			game.player.position=game.repair.pickup_position(); game.amu.position=game.repair._pickup_helper_goal(); game.repair.interact()
			await create_timer(1.5).timeout
			game.player.damage(1000)
			check(game.failed,"carrying damage reaches the real failure handler")
			game.retry_checkpoint()
			check(not game.failed and not game.player.carrying and game.repair.step=="pickup" and game.world.v2_repair_is_enabled(0),"carrying death restores one prepared timber and keeps the first repaired gap")
		if id=="traversal": check(game.traversal.fixed and game.traversal.checkpoint==1,"middle support repair survives process restart")
		if id=="relay": check(game.relay.observed and game.relay.phase=="signal","unfinished relay restores a controllable signal step")

	game.main_menu()
	game.save_store.path="user://v2_corruption_test.json"
	var file=FileAccess.open(game.save_store.path,FileAccess.WRITE); file.store_string('{broken'); file.close()
	check(not game.continue_story() and not game.save_store.last_error.is_empty(),"corrupt JSON falls back to title with explanation")
	check(FileAccess.get_file_as_string(game.save_store.path)=='{broken',"invalid save is preserved rather than overwritten")
	game.begin(true)
	check(not game.modern.active and not game.player.carrying and not game.player.climbing,"restart clears all special modes")
	check(not game.world.v2_repair_is_enabled(0) and not game.world.v2_repair_is_enabled(1),"restart clears completed repair geometry")
	game.queue_free(); await process_frame; await create_timer(.4).timeout
	print("V2 RECOVERY FAILURES ",errors); quit(1 if errors else 0)
