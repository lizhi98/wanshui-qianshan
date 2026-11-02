extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v413_surface_probe.json";g.begin();g.flags.intro_done=true;g.hud.center_title.text="";g.set_process(false);g.set_physics_process(false);g.stage="DISCOVERY"
 var a=g.quartermaster;a.position=g.world.MEMORIAL;a.rotation.y=2.214;a.pose_name="seated"
 var probe=load("res://qa/shoe_surface.gd").new();await create_timer(2).timeout;print("SEATED_RENDERED_SOLES ",probe.sample(a)," bone_offsets=",a.visual.sole_offsets)
 for b in [g.player,g.amu,g.zhou]:
  if b==g.player:b.restore(Vector3(0,.02,37))
  else:b.restore();b.position=Vector3(0,.02,37)
  b.visual.pose("");b.visual.mode="idle";b.visual.speed=0
  await create_timer(1).timeout;print("STANDING_RENDERED_SOLES ",b.name," ",probe.sample(b)," bone_offsets=",b.visual.sole_offsets)
 g.main_menu();g.queue_free();await process_frame;quit()
