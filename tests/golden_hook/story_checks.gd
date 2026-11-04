extends SceneTree
var errors:=0
var checks:=0
func _initialize(): call_deferred("run")
func check(value:bool,label:String):
	checks+=1; print(("PASS " if value else "FAIL ")+label)
	if not value: errors+=1
func run():
	check(FileAccess.file_exists("res://game/golden_hook/chapter_state.gd"),"chapter rules module exists")
	if errors: quit(1); return
	var script=load("res://game/golden_hook/chapter_state.gd")
	var s=script.new()
	check(s.step=="supplies","new chapter starts with checking supplies")
	check(not s.perform("collect_hook") and not s.add_fish(),"future interactions cannot skip the story")
	check(not s.perform("deliver_supplies"),"empty delivery cannot skip checks or gathering")
	for action in ["bag_a","bag_b","comrade_a","comrade_b","ration","greens_a","greens_b"]:
		check(s.perform(action),"supply interaction works: "+action)
		check(not s.perform(action),"supply interaction is idempotent: "+action)
	check(s.inventory.greens==2,"two gathered items are actual inventory")
	check(s.perform("deliver_supplies") and s.step=="craft","complete supplies lead to craft")
	for action in ["needle","thread","branch"]: check(s.perform(action),"craft material pickup: "+action)
	check(s.perform("place_parts") and s.inventory.needle==0 and s.inventory.branch==0,"placing parts consumes carried materials")
	for action in ["heat","bend","tie","mount"]: check(s.perform(action),"ordered craft action: "+action)
	var hook=s.hook_id
	check(s.inventory.hook==1 and s.step=="first_fishing","one persistent hook opens the first fishing task")
	check(s.add_fish() and s.step=="first_fishing","first fish alone does not complete the quota")
	check(s.add_fish() and s.step=="cook_fish","two input-earned fish unlock cooking")
	check(not s.add_fish() and s.inventory.fish==2,"cooking state cannot mint excess fish")
	check(s.perform("put_fish") and s.inventory.fish==0,"fish goes into the physical pot and leaves inventory")
	check(s.perform("put_greens") and s.inventory.greens==0,"greens are consumed for soup")
	for action in ["light_fire","finish_soup","serve_a","serve_b","drink_soup"]: check(s.perform(action),"cooking/serving action: "+action)
	check(s.step=="secret" and s.inventory.soup==0,"three portions restore the young comrades; elder has none")
	for action in ["understand","continue_march","find_elder"]: check(s.perform(action),"narrative interaction: "+action)
	check(s.step=="last_fishing","finding elder enables the final actual catch")
	check(s.add_fish() and s.inventory.fish==1,"final fish is earned by the same catch API")
	for action in ["last_cook","last_deliver","farewell"]: check(s.perform(action),"final assistance: "+action)
	check(s.step=="keepsake" and s.elder_fate=="sacrificed","literary outcome has no speed or timeout parameter")
	check(s.perform("collect_hook") and s.hook_id==hook and s.inventory.keepsake==1,"original hook becomes the unique keepsake")
	check(not s.perform("collect_hook"),"keepsake cannot be duplicated")
	check(s.perform("leave") and s.step=="archive","onward travel opens historical archive")
	var restored=script.new()
	check(restored.restore(s.snapshot()) and restored.hook_id==hook and restored.inventory.keepsake==1,"chapter progress and unique item round-trip")
	var bad=s.snapshot(); bad.inventory.fish=-1
	check(not restored.restore(bad),"negative inventory is rejected without corrupting existing state")
	bad=s.snapshot(); bad.step="unknown"
	check(not restored.restore(bad),"unknown chapter step is rejected")
	check(FileAccess.file_exists("res://game/golden_hook/save_store.gd"),"atomic store adapter exists")
	if FileAccess.file_exists("res://game/golden_hook/save_store.gd"):
		var store=load("res://game/golden_hook/save_store.gd").new()
		store.path="user://golden_hook_unit_test.json"
		var data={"version":3,"chapter":s.snapshot(),"position":[-8,0,8],"elapsed":123.0}
		check(store.write(data) and store.read().chapter.step=="archive","inherited atomic store writes and reads new chapter")
		data.position=[0,"bad",0]
		check(not store.write(data) and store.read().chapter.step=="archive","bad writes preserve the previous good save")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path))
	print("STORY_RESULT ",JSON.stringify({"checks":checks,"failures":errors}))
	quit(1 if errors else 0)
