extends RefCounted
const STAGES=["INTRO","ROUTE_FINDING","BLIZZARD","SLOPE_COLLAPSE","REUNION","SUMMIT","COMPLETE"]
var path="user://snow_campaign_v4.json"
var last_error:=""
func vector(value)->bool:
	if value is not Array or value.size()!=3:return false
	for n in value:
		if typeof(n) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(n)) or absf(float(n))>2000:return false
	return true
func number(value)->bool:return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value))
func valid(data:Dictionary)->bool:
	if data.get("version")!=1 or data.get("chapter")!="snow" or data.get("stage") not in STAGES:return false
	if not vector(data.get("position")) or data.get("flags") is not Dictionary or data.get("stats") is not Dictionary or data.get("actors") is not Array:return false
	for field in ["elapsed","weather_clock","retries"]:
		var value=data.get(field)
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)) or value<0:return false
	for value in data.flags.values():
		if typeof(value)!=TYPE_BOOL:return false
	for name in ["jumps","signals","clues","walked_m"]:
		if not number(data.stats.get(name)) or data.stats[name]<0:return false
	for field in ["observed","shelters"]:
		if data.get(field,{}) is not Dictionary:return false
		for value in data.get(field,{}).values():
			if typeof(value)!=TYPE_BOOL:return false
	if data.actors.size()!=4:return false
	for actor in data.actors:
		if actor is not Dictionary or not vector(actor.get("position")) or actor.get("route") is not Array:return false
		if not number(actor.get("speed")) or actor.speed<.1 or actor.speed>6 or typeof(actor.get("moving"))!=TYPE_BOOL or actor.route.size()>64:return false
		if not number(actor.get("vertical_speed",0)) or absf(float(actor.get("vertical_speed",0)))>50:return false
		for point in actor.route:
			if not vector(point):return false
	return true
func write(data:Dictionary)->bool:
	last_error=""
	if not valid(data):last_error="雪山检查点字段无效，原存档已保留。";return false
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if not file:last_error="无法写入雪山存档。";return false
	file.store_string(JSON.stringify(data,"\t"));file.flush();file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK
func read()->Dictionary:
	last_error=""
	if not FileAccess.file_exists(path):return {}
	var json=JSON.new()
	if json.parse(FileAccess.get_file_as_string(path))!=OK or json.data is not Dictionary or not valid(json.data):last_error="雪山存档损坏，可从新关卡开始；原文件保留。";return {}
	return json.data
func exists()->bool:return not read().is_empty()
