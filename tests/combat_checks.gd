extends SceneTree
var errors := 0
func _initialize(): call_deferred("run")
func check(value: bool, description: String):
	print(("PASS: " if value else "FAIL: ")+description)
	if not value: errors += 1
func run():
	var game = load("res://game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.4).timeout
	game.finish_intro()
	game.player.position = Vector3(-1.9,0.1,2.05)
	await physics_frame
	await physics_frame
	game.combat.fire_enemy(game.enemies[0])
	check(game.player.health == 100,"bridgehead cover blocks enemy bullets")
	game.player.position = Vector3(0,0.1,0.3)
	await physics_frame
	game.combat.fire_enemy(game.enemies[0])
	check(game.player.health<100,"exposed player receives ray-based damage")
	game.combat.ammo = 1
	game.combat.reserve = 2
	game.combat.reload()
	await create_timer(2.3).timeout
	check(game.combat.ammo == 3 and game.combat.reserve == 0,"reload transfers only available reserve")
	game.say("阿木","测试对白",0.4)
	check(not game.combat.fire_player(),"dialogue blocks simultaneous shooting")
	await create_timer(0.5).timeout
	game.player.position = Vector3(0,0.1,3)
	game.player.locked = true
	game.combat.ammo = 5
	check(not game.combat.fire_player(),"interaction lock blocks shooting")
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(1 if errors else 0)
