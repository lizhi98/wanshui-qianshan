# Preparation, restoration and interruption contract. Full input repeat in carry_acceptance.gd.
extends "res://tests/v2/carry_acceptance.gd"
func run():
	game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	game.save_store.path="user://repair_contract_only.json"
	await wait(.4)
	for action in InputMap.get_actions(): InputMap.action_erase_events(action)
	await fixture(0,false)
	game.player.position=game.repair.material_position("bad"); game.repair.interact()
	check(game.repair.step=="select" and game.repair.material=="","rotten material rejected without trapping selection")
	game.player.position=game.repair.material_position("cracked"); game.repair.interact()
	check(game.repair.material=="cracked" and game.repair.required_rounds==2,"cracked board keeps two-round reinforcement")
	game.repair.interact(); check(game.repair.step=="position","misaligned preparation cannot be skipped")
	await press("move_right",.65); await press("interact"); await press("interact",1.6)
	check(game.repair.step=="position" and game.repair.prep_round==1,"first binding opens second support")
	await press("move_back",.55); await press("interact"); await press("interact",1.6)
	check(game.repair.step=="check","second support requires its own binding")
	await press("jump"); await wait(.25)
	check(game.repair.rope_assist and game.repair.step=="pickup","reinforced material retains later rope assistance")
	game.player.position=Vector3(0,0,18); game.repair.interact()
	check(game.repair.step=="pickup" and not game.player.carrying,"distance gate prevents remote pickup")
	for phase in ["join","npc_ready","lifting","carry","lowering","align","secure","place_check","recover"]:
		game.repair.step=phase
		var saved=game.repair.snapshot()
		check(saved.step=="pickup","unsafe state normalized on save "+phase)
		game.repair.start(saved)
		check(game.repair.active_board.get_parent()==game.repair and not game.player.carrying and not game.player.locked,"restoration has one board and free control "+phase)
	for phase in ["position","tie","check","join","npc_ready","lifting","carry","lowering","align","secure","place_check"]:
		game.repair.start({"step":"pickup","material":"good"})
		game.repair.step=phase; game.player.locked=true
		game.repair.cancel_interaction(); await wait(.6)
		check(not game.player.locked and not game.player.carrying and game.player.visual.hand_targets.is_empty(),"cancel releases input and IK "+phase)
	await fixture()
	check(await pickup(),"real helper join for collision recovery")
	var leader=game.player.position
	game.world.box(Vector3(4,2,.25),leader+Vector3(0,1,-1),game.world.wood)
	await physics_frame
	await press("move_forward",1.2)
	check(not game.player.locked and not game.failed,"contact with wall cannot lock controls")
	var contact=game.player.position
	await press("move_back",.7)
	check(game.player.position.z>contact.z+.3,"leader and rig can retreat from collision")
	await press("reload"); await wait(.6)
	check(game.repair.step=="pickup" and not game.player.locked,"blocked carry can be explicitly reset")
	finish()
