extends SceneTree
var errors := 0
func _initialize(): call_deferred("run")
func run():
	await process_frame
	var manager=root.get_node("DialogueManager")
	var total_chars=0
	var total_lines=0
	for file in DirAccess.get_files_at("res://story"):
		if not file.ends_with(".dialogue"): continue
		var text=FileAccess.get_file_as_string("res://story/"+file)
		var resource=manager.create_resource_from_text(text)
		if not resource:
			errors+=1
			continue
		var line=await manager.get_next_dialogue_line(resource,"start",[{"choice":0}])
		var count=0
		while line and count<100:
			total_chars+=line.text.length()
			total_lines+=1
			var next=line.next_id
			if not line.responses.is_empty(): next=line.responses[0].next_id
			line=await manager.get_next_dialogue_line(resource,next,[{"choice":0}])
			count+=1
		print("STORY ",file,": ",count," ordered lines")
	print("STORY TOTAL ",total_lines," lines / ",total_chars," characters (branch 0 + optional scenes)")
	quit(errors)
