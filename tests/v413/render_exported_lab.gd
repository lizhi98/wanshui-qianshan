extends SceneTree
# Loads the release EXE's embedded pack. Only fixture presentation is changed:
# hide unrelated world geometry behind the isolated flat/ramp animation stage.
func _initialize():call_deferred("run")
func run():
 var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g)
 var runner=load("res://qa/animation_lab.gd").new();root.add_child(runner);runner.run(g)
 if runner.case_name in ["A","C"]:g.world.hide()
 runner.folder=ProjectSettings.globalize_path("user://verification/animation_v413_clean/"+runner.case_name);DirAccess.make_dir_recursive_absolute(runner.folder)
