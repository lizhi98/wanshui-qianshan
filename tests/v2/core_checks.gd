extends SceneTree
var errors=0
func _initialize(): call_deferred("run")
func check(value:bool,label:String):
	print(("PASS " if value else "FAIL ")+label)
	if not value: errors+=1
func run():
	for file in ["objectives.gd","save_store.gd"]: check(FileAccess.file_exists("res://game/v2/"+file),"V2 foundation exists: "+file)
	if errors: quit(1); return
	var ledger=load("res://game/v2/objectives.gd").new()
	check(ledger.current=="march","new game starts with movement")
	check(not ledger.finish("repair"),"future completion cannot skip chapters")
	check(ledger.finish("march") and ledger.current=="recon","matching event advances one chapter")
	check(not ledger.finish("march"),"duplicate completion cannot advance twice")
	var restored=load("res://game/v2/objectives.gd").new()
	check(restored.restore(ledger.snapshot()) and restored.current=="recon","objective progress round trips")
	check(not restored.restore({"current":"unknown","done":{}}),"invalid task ledger is rejected")
	var store=load("res://game/v2/save_store.gd").new()
	store.path="user://v2_core_test.json"
	var data={"version":3,"ledger":ledger.snapshot(),"modules":{},"position":[0,0,30],"elapsed":12.0}
	check(store.write(data),"V3 checkpoint writes atomically")
	check(store.read().ledger.current=="recon","V3 checkpoint reloads")
	data.position=[0,"bad",30]
	check(not store.valid(data),"nonnumeric coordinates are rejected")
	data.position=[0,0,30]; data.version=2
	check(not store.valid(data),"legacy schema cannot masquerade as V3")
	data.version=3; data.modules={"repair":{"site":"corrupt","repaired":[true]}}
	check(not store.valid(data),"malformed module fields are rejected before controller restore")
	data.modules={"modern":{"placed":[{"bad":true}]}}
	check(not store.valid(data),"malformed reconstruction arrays are rejected")
	var file=FileAccess.open(store.path,FileAccess.WRITE); file.store_string('{"version":2,"stage":"carrying"}'); file.close()
	check(store.read().is_empty() and not store.last_error.is_empty(),"legacy save falls back safely with an explanation")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path))
	quit(1 if errors else 0)
