extends "res://game/snow/save_store.gd"
const ACTS=["CAMP","MARCH","STORM","SEARCH","DISCOVERY","SALUTE","CONTINUE","COMPLETE"]
func _init():
	path="user://memorial_campaign_v413.json"
	var old="user://memorial_campaign_v412.json"
	if not FileAccess.file_exists(path) and FileAccess.file_exists(old):
		var data=JSON.parse_string(FileAccess.get_file_as_string(old))
		if data is Dictionary and valid(data):write(data)
func valid(data:Dictionary)->bool:
	if not number(data.get("version")) or data.version!=int(data.version) or int(data.version) not in [41,412] or data.get("chapter")!="memorial" or data.get("stage") not in ACTS:return false
	if not vector(data.get("position")) or data.get("flags") is not Dictionary or data.get("stats") is not Dictionary:return false
	for field in ["elapsed","weather_clock","retries","stock","crowd_clock"]:
		if not number(data.get(field)) or data[field]<0:return false
	if data.stock>3 or data.get("carrying") is not bool or data.get("actors") is not Array or data.actors.size()!=8:return false
	for key in ["jumps","signals","clues","walked_m","delivered"]:
		if not number(data.stats.get(key)) or data.stats[key]<0:return false
	if data.stats.delivered>3 or int(data.stock)+int(data.stats.delivered)+(1 if data.carrying else 0)!=3:return false
	if data.get("crowd_s",[]) is not Array or data.get("crowd_s",[]).size()>72:return false
	for value in data.get("crowd_s",[]):
		if not number(value) or absf(value)>1600:return false
	if data.get("action","") not in ["","take","give","old_talk","clear","count","inspect","reveal","salute"]:return false
	for name in ["action_clock","action_duration"]:
		if not number(data.get(name,0)) or data.get(name,0)<0 or data.get(name,0)>240:return false
	if data.stage!="CAMP" and not data.flags.get("march_started",false):return false
	if data.stage in ["SEARCH","DISCOVERY","SALUTE","CONTINUE","COMPLETE"] and not data.flags.get("storm_signal",false):return false
	if data.stage in ["DISCOVERY","SALUTE","CONTINUE","COMPLETE"] and not data.flags.get("strap_found",false):return false
	if data.stage in ["SALUTE","CONTINUE","COMPLETE"] and not data.flags.get("identity_revealed",false):return false
	if data.stage in ["CONTINUE","COMPLETE"] and not data.flags.get("honored",false):return false
	for value in data.flags.values():
		if typeof(value)!=TYPE_BOOL:return false
	if data.get("version")==412 and not valid_director(data.get("director")):return false
	for a in data.actors:
		if a is Dictionary and a.has("yaw") and (not number(a.yaw) or absf(a.yaw)>100):return false
		if a is not Dictionary or not vector(a.get("position")) or a.get("route") is not Array:return false
		if a.get("moving") is not bool or a.get("coat") is not bool or a.get("pose") not in ["","shiver","pack","handover","salute","seated","inspect"]:return false
		if not number(a.get("vertical_speed",0)) or absf(float(a.get("vertical_speed",0)))>50:return false
		for point in a.route:
			if not vector(point):return false
		if a.route.size()>80 or not number(a.get("speed")) or a.speed<.1 or a.speed>6:return false
	return true

func valid_director(value)->bool:
	if value is not Dictionary:return false
	if not number(value.get("phase")) or value.phase< -1 or value.phase>8:return false
	if not number(value.get("clock")) or value.clock<0 or value.clock>240:return false
	for key in ["reported","marching","music_cut"]:
		if value.get(key) is not bool:return false
	for who in ["commander","guard"]:
		var actor=value.get(who)
		if actor is not Dictionary or not vector(actor.get("position")) or actor.get("route") is not Array:return false
		if actor.get("pose") not in ["","witness","concern","anger","demand","hesitate","lowered","shock","salute"]:return false
		if actor.get("moving") is not bool or actor.route.size()>80:return false
		for point in actor.route:
			if not vector(point):return false
	return true
