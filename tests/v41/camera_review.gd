extends SceneTree
# Focused staging fixture; deliberately positions actors. Not a playthrough.
var game
func _initialize():call_deferred("run")
func shot(label:String):
	await process_frame;await process_frame;RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://test_evidence/v41_fixtures/"+label+".png")
func run():
	game=load("res://game/memorial/main.tscn").instantiate();root.add_child(game);await create_timer(.4).timeout
	game.save_store.path="user://v41_camera_fixture.json";game.begin();game.flags.intro_done=true;game.hud.center_title.text=""
	game.stage="DISCOVERY";game.quartermaster.position=game.world.MEMORIAL;game.quartermaster.rotation.y=2.214;game.quartermaster.pose_name="seated"
	game.player.restore(game.world.MEMORIAL+Vector3(0,.1,-1.7));game.zhou.position=game.world.MEMORIAL+Vector3(-1.4,.1,-.7);game.zhou.moving=false
	for i in game.crowd.units.size():game.crowd.units[i].s=game.world.route.lengths[12]+i*3.2
	game._start_action("reveal","",35);await create_timer(3).timeout;await shot("07_reveal_camera_fixed")
	game.action_clock=34.95;await create_timer(.2).timeout;game.interact();await create_timer(3.1).timeout;await shot("08_salute_camera_fixed")
	game.main_menu();game.queue_free();await process_frame;quit()
