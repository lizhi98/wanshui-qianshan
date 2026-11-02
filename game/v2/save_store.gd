extends RefCounted
const VERSION=3
var path="user://campaign_v3.json"
var last_error=""
func _init():
	# Non-destructive first-run migration after the product rename.
	var previous=OS.get_user_data_dir().get_base_dir().path_join("万水千山：战火中的木板 V2.0")
	for name in ["campaign_v3.json","remaster_settings.cfg"]:
		var target=OS.get_user_data_dir().path_join(name)
		if not FileAccess.file_exists(target) and FileAccess.file_exists(previous.path_join(name)):
			DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
			DirAccess.copy_absolute(previous.path_join(name),target)

func valid(data:Dictionary)->bool:
	if int(data.get("version",0))!=VERSION: return false
	if data.get("ledger") is not Dictionary or data.get("modules") is not Dictionary: return false
	var ledger=load("res://game/v2/objectives.gd").new()
	if not ledger.restore(data.ledger): return false
	var pos=data.get("position")
	if pos is not Array or pos.size()!=3: return false
	for coordinate in pos:
		if typeof(coordinate) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(coordinate)) or absf(float(coordinate))>500: return false
	var elapsed=data.get("elapsed",0.0)
	if typeof(elapsed) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(elapsed)) or float(elapsed)<0: return false
	for value in data.modules.values():
		if value is not Dictionary: return false
	if data.has("assault"):
		if data.assault is not Dictionary: return false
		for key in data.assault:
			var value=data.assault[key]
			if key=="enemy_health":
				if value is not Array or value.size()!=2: return false
				for health in value:
					if not _number(health) or health<0 or health>100: return false
			elif key=="bridgehead_cleared":
				if typeof(value)!=TYPE_BOOL: return false
			elif key in ["passed","fallen","wounded"]:
				if not _number(value) or value<0 or value>100000: return false
			else: return false
	if data.has("vanguard"):
		if data.vanguard is not Dictionary:return false
		for key in data.vanguard:
			if key not in ["sacrifice_seen","response_seen"] or typeof(data.vanguard[key])!=TYPE_BOOL:return false
	for id in data.modules:
		if id not in ["march","recon","escort","repair","traversal","relay","modern"]: return false
		if not _module_valid(id,data.modules[id]): return false
	return true
func _number(value)->bool: return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value))
func _vector(value)->bool:
	if value is not Array or value.size()!=3: return false
	for n in value:
		if not _number(n) or absf(float(n))>500: return false
	return true
func _module_valid(id:String,state:Dictionary)->bool:
	for field in ["site","leg","checkpoint","prep_round","lateral","depth","alignment","angle","tension","selected","choice","sites_completed"]:
		if state.has(field) and (not _number(state[field]) or absf(float(state[field]))>100): return false
	for field in ["jumped","supply","blocker_cleared","rope_assist","fixed","crisis_fixed","observed","clear","relay_clear","allies_passed","compared"]:
		if state.has(field) and typeof(state[field])!=TYPE_BOOL: return false
	for field in ["safe_position","npc_safe_position"]:
		if state.has(field) and not _vector(state[field]): return false
	if state.has("repaired"):
		if state.repaired is not Array or state.repaired.size()!=2: return false
		for value in state.repaired:
			if typeof(value)!=TYPE_BOOL: return false
	if state.has("enemy_health"):
		if state.enemy_health is not Array or state.enemy_health.size()!=2: return false
		for value in state.enemy_health:
			if not _number(value) or value<0 or value>100: return false
	if state.has("found"):
		if state.found is not Array or state.found.size()>3: return false
		for value in state.found:
			if value not in ["firepoint","gap","cover"]: return false
	if state.has("route") and state.route not in ["","A","B"]: return false
	if state.has("material") and state.material not in ["","good","cracked"]: return false
	if id=="repair" and state.has("step") and state.step not in ["select","position","tie","check","pickup","done"]: return false
	for field in ["collected","classified","placed"]:
		if not state.has(field): continue
		if state[field] is not Array or state[field].size()>3: return false
		for value in state[field]:
			if not _number(value) or int(value) not in [0,1,2]: return false
	for field in ["allies","actors"]:
		if not state.has(field): continue
		if state[field] is not Array or state[field].size()>2: return false
		for actor in state[field]:
			if field=="actors":
				if not _vector(actor): return false
				continue
			if actor is not Dictionary or not _vector(actor.get("position")): return false
			if actor.get("route",[]) is not Array: return false
			for point in actor.get("route",[]):
				if not _vector(point): return false
	return true
func write(data:Dictionary)->bool:
	last_error=""
	if not valid(data): last_error="检查点字段不完整，未覆盖原文件。"; return false
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if not file: last_error="无法写入存档目录。"; return false
	file.store_string(JSON.stringify(data,"\t")); file.flush(); file.close()
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))!=OK:
		last_error="无法替换存档文件。"; return false
	return true
func read()->Dictionary:
	last_error=""
	if not FileAccess.file_exists(path): return {}
	var parser=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK or parser.data is not Dictionary:
		last_error="存档内容损坏，可安全开始新故事。"; return {}
	var data:Dictionary=parser.data
	if int(data.get("version",0))!=VERSION:
		last_error="这是旧版进度。V2玩法已改变，请从新故事开始；旧文件保持不变。"; return {}
	if not valid(data): last_error="存档状态无效，可安全开始新故事。"; return {}
	return data
func exists()->bool: return not read().is_empty()
