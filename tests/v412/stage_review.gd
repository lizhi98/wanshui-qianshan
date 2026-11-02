extends SceneTree
var g
func _initialize():call_deferred("run")
func shot(label):
	if DisplayServer.get_name()=="headless":return
	await process_frame;await process_frame;RenderingServer.force_draw(false);root.get_texture().get_image().save_png("res://test_evidence/v412/"+label+".png")
func run():
	DirAccess.make_dir_recursive_absolute("res://test_evidence/v412")
	g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.5).timeout;g.save_store.path="user://v412_staging_fixture.json";g.begin();g.flags.intro_done=true;g.stage="DISCOVERY";g.hud.center_title.text=""
	var i=0
	for a in g.actors():
		a.moving=false;a.pose_name=""
		if a==g.quartermaster:a.position=g.world.MEMORIAL;a.rotation.y=2.214;a.pose_name="seated";continue
		a.position=g.world.MEMORIAL+Vector3(-3+float(i)*.9,.03,-3.8-float(i%3)*.6);i+=1
	g.player.restore(g.world.MEMORIAL+Vector3(1.2,.03,-1.7));g.director.marching=true
	g.director.commander.position=g.world.route.POINTS[11];g.director.commander.walk([g.world.MEMORIAL+Vector3(-1.1,0,-1.7)],2.6)
	g.director.guard.position=g.world.MEMORIAL+Vector3(1.4,.03,-2)
	g._start_action("inspect","",8);await create_timer(3).timeout;await shot("01_seated_contact")
	await create_timer(6).timeout;g._start_action("reveal","",0)
	while g.action=="reveal":
		if g.director.phase==1:await shot("02_anger")
		if g.director.phase==2:await shot("02b_hand")
		if g.director.phase==7:await shot("03_shock")
		await create_timer(.5).timeout
	g.interact();await create_timer(3.5).timeout;await shot("04_salute")
	g.main_menu();g.queue_free();await process_frame;quit()
