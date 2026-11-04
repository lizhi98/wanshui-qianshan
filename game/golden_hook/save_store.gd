extends "res://game/v2/save_store.gd"
## Reuses the verified atomic write/read and schema version; the chapter payload
## has its own validated namespace so V2's existing campaign_v3.json is intact.
func _init():
	path="user://golden_hook_chapter3.json"
	if FileAccess.file_exists(path): return
	var previous=OS.get_user_data_dir().get_base_dir().path_join("万水千山：战火中的木板 V2.0").path_join("golden_hook_chapter3.json")
	if not FileAccess.file_exists(previous): return
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(previous))
	if parsed is Dictionary and valid(parsed): write(parsed)
func valid(data:Dictionary)->bool:
	if int(data.get("version",0))!=3 or data.get("chapter") is not Dictionary: return false
	var story=load("res://game/golden_hook/chapter_state.gd").new()
	if not story.restore(data.chapter): return false
	if not _vector(data.get("position")): return false
	var cast=data.get("cast",{})
	if cast is not Dictionary or cast.size()>3:return false
	for id in cast:
		if id not in ["elder","shi","qing"] or cast[id] is not Dictionary:return false
		var actor=cast[id]
		if not _vector(actor.get("position")) or not _number(actor.get("yaw")) or absf(float(actor.yaw))>100:return false
		if actor.get("posture") not in ["standing","weak","seated","kneel","collapsed"] or actor.get("held") not in ["","bowl","scraps"]:return false
		if actor.get("route") is not Array or actor.route.size()>16:return false
		for point in actor.route:
			if not _vector(point):return false
		if not _number(actor.get("speed")) or actor.speed<0 or actor.speed>3.2:return false
	var elapsed=data.get("elapsed",0)
	return _number(elapsed) and elapsed>=0
