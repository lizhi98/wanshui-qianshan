extends Node
## Actual viewport mouse events on all three chapter buttons, including returns.
var failures:=0
func wait_frames(n:=3):
	for i in n:await get_tree().process_frame
func button(prefix:String):
	for b in get_tree().current_scene.find_children("*","Button",true,false):
		if b.visible and str(b.text).begins_with(prefix):return b
	return null
func click(prefix:String)->bool:
	await wait_frames(4)
	var b=button(prefix)
	if not b:failures+=1;print("NAV_FAIL missing button ",prefix);return false
	var p=b.get_global_rect().get_center()
	var move=InputEventMouseMotion.new();move.position=p;get_tree().root.push_input(move,true)
	var down=InputEventMouseButton.new();down.position=p;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;get_tree().root.push_input(down,true)
	await wait_frames(1)
	var up=InputEventMouseButton.new();up.position=p;up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;get_tree().root.push_input(up,true)
	await wait_frames(8);return true
func assert_scene(path:String):
	var good=get_tree().current_scene.get_script().resource_path==path
	print(("NAV_PASS " if good else "NAV_FAIL ")+path)
	if not good:failures+=1
func run():
	await wait_frames(6)
	for pair in [["第一关","res://game/v2/campaign.gd"],["第二关","res://game/memorial/campaign.gd"],["第三关","res://game/golden_hook/chapter.gd"]]:
		if not await click(pair[0]):break
		assert_scene(pair[1]);await get_tree().create_timer(.4).timeout
		if pair[0]!="第三关":
			var count=get_tree().current_scene.audio.voice_manifest.size();print("NAV_VOICE_MANIFEST ",pair[0]," ",count)
			if count==0:failures+=1
		if not await click("章节选择"):break
		assert_scene("res://game/chapters/manager.gd")
	print("UNIFIED WINDOWS NAVIGATION ","PASS" if failures==0 else "FAIL", " actual_mouse_events=true")
	await wait_frames(3);OS.delay_msec(80);get_tree().quit(0 if failures==0 else 1)
