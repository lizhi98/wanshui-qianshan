extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var routes=load("res://game/chapters/manager.gd").CHAPTERS
	var ok=routes.has("fishhook") and routes.get("fishhook","")=="res://game/golden_hook/main.tscn"
	print("PASS three chapters share one router" if ok else "FAIL third chapter missing from unified router")
	for id in routes:
		if not ResourceLoader.exists(routes[id]): ok=false; print("FAIL missing chapter ",id)
	quit(0 if ok else 1)
