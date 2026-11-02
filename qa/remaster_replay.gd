# Source/CLI entry; release builds use -- --verify-replay.
extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var runner=load("res://qa/replay_controller.gd").new()
	root.add_child(runner)
	runner.run()
