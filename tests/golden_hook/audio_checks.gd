extends SceneTree
var errors:=0
func _initialize(): call_deferred("run")
func check(value:bool,label:String):
	print(("PASS " if value else "FAIL ")+label)
	if not value: errors+=1
func run():
	var data=load("res://game/golden_hook/dialogue_data.gd").GROUPS
	var seen={}; var total=0.0
	for group in data:
		for row in data[group]:
			check(not seen.has(row.id),"unique subtitle/audio line ID: "+row.id); seen[row.id]=true
			var path="res://assets/golden_hook/audio/voice/"+row.id+".wav"
			var exists=FileAccess.file_exists(path)
			check(exists,"offline voice exists: "+row.id)
			if exists:
				var stream=AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(path))
				check(stream and stream.get_length()>.5,"voice decodes with nonzero duration: "+row.id)
				if stream: total+=stream.get_length()
	for id in ["shortage","hope","warm","urgent","memory","wind","cast","bite","splash","pull","slip","pickup","fire"]:
		check(FileAccess.file_exists("res://assets/golden_hook/audio/"+id+".wav"),"original offline audio: "+id)
	print("AUDIO_RESULT ",JSON.stringify({"lines":seen.size(),"spoken_seconds":total,"failures":errors}))
	quit(1 if errors else 0)
