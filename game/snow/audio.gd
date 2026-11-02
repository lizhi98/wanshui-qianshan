extends "res://game/remaster/audio.gd"
func _ready():
	super._ready()
	var path="res://assets/snow/voices/manifest.json"
	if FileAccess.file_exists(path):
		var extra=JSON.parse_string(FileAccess.get_file_as_string(path))
		if extra is Dictionary:voice_manifest.merge(extra,true)
func track_for_mission()->String:
	if mission.stage=="COMPLETE" or mission.outro_active:return "snow_summit"
	if mission.stage in ["SLOPE_COLLAPSE","REUNION"]:return "snow_crisis"
	return "snow_walk"
func _process(delta):
	super._process(delta)
	if mission.weather:wind.volume_db=-34+mission.weather.strength*9+mission.weather.gust*7
