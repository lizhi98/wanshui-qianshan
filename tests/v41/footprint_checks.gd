extends SceneTree
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func run():
	var game=load("res://game/snow/main.tscn").instantiate();root.add_child(game);await create_timer(.4).timeout
	var marks=game.world._footprints();var p=game.world.route.POINTS[8]
	check(marks.stamp(p,Vector3.FORWARD,true),"sole decal raycasts onto a snow slope")
	var mark=marks.marks.back();check(mark.node is Decal and not mark.node is MeshInstance3D,"boot print is a projected decal rather than an opaque rectangular plane")
	check(mark.node.global_basis.y.dot(mark.normal)>.999,"decal projection follows the actual ground normal")
	var img=load("res://assets/memorial/footprints/sole_snow.png").get_image()
	check(img.get_pixel(0,0).a==0 and img.get_pixel(64,80).a>.5,"sole mask has transparent corners and a boot-shaped interior")
	var previous=marks.marks.size();game.player.locked=true
	for i in 30:marks.track(game.player)
	check(marks.marks.size()==previous,"stationary character does not emit timed footprints")
	for i in 175:marks.stamp(p+Vector3((i%5)*.12,0,0),Vector3.FORWARD,i%2==0)
	check(marks.marks.size()<=marks.LIMIT,"footprint node budget stays bounded")
	game.main_menu();game.audio.clear_voice();game.queue_free();await process_frame;quit(1 if errors else 0)
