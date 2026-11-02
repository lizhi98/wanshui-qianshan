extends Node
signal finished(key: String)
var mission
var active := false
var loading := false
var automatic := false
var key := ""
var resource
var line
var visible_chars := 0.0
var read_clock := 0.0
var line_count := 0
var visited: Array[String] = []
var branch_choice := ""
var _next := ""
var fully_revealed := false
var generation := 0

func start(dialogue_key: String, from_id := ""):
	if active: return
	key = dialogue_key
	generation+=1
	active = true
	loading = false
	visited = []
	line_count = 0
	mission.player.locked = true
	mission.player.aiming = false
	mission.player.movement_velocity = Vector3.ZERO
	for actor in [mission.player,mission.amu,mission.zhou]:
		actor.velocity = Vector3.ZERO
		actor.visual.speed = 0.0
		if actor!=mission.player: actor.moving=false
	mission.dialogue_locked = true
	mission.combat.reloading = false
	mission.director.enter()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var runtime = get_node("/root/DialogueManager")
	resource = runtime.create_resource_from_text(FileAccess.get_file_as_string("res://story/"+key+".dialogue"))
	await _show_next(from_id if not from_id.is_empty() else "start")

func _show_next(id: String):
	loading = true
	var request=generation
	var next_line = await get_node("/root/DialogueManager").get_next_dialogue_line(resource,id,[mission])
	if not active or request!=generation: return
	line=next_line
	loading = false
	if not line:
		close()
		return
	_next = line.next_id
	visible_chars = 0
	fully_revealed = false
	read_clock = 0
	line_count += 1
	visited.append(line.text)
	var speaker = mission.actor_by_name(line.character)
	var listener = mission.player if speaker!=mission.player else mission.dialogue_partner()
	for actor in [mission.player,mission.amu,mission.zhou]:
		actor.visual.speed = 0.0
		actor.visual.armed = false
		actor.visual.look_enabled = true
		actor.visual.look_target = (listener if actor==speaker else speaker).global_position+Vector3(0,1.45,0)
		actor.visual.mode = "talk" if actor==speaker else "idle"
		if actor != mission.player:
			actor.moving = false
			actor.fixed_pose = "talk" if actor==speaker else "idle"
	var gesture_name = "talk"
	var shot = ["two","medium","shoulder","close","medium"][line_count%5]
	for tag in line.tags:
		if tag.begins_with("gesture="): gesture_name = tag.trim_prefix("gesture=")
		if tag.begins_with("shot="): shot = tag.trim_prefix("shot=")
	for actor in [mission.player,mission.amu,mission.zhou]:
		actor.visual.set_conversation(actor==speaker,gesture_name,line_count)
	mission.director.frame(shot,speaker,listener)
	mission.hud.show_line(line.character,line.text,line.responses)
	mission.hud.set_text_reveal(0)
	mission.audio.dialogue_tick()

func advance():
	if not active or loading or not line: return
	if visible_chars<line.text.length():
		visible_chars = line.text.length()
		fully_revealed = true
		mission.hud.set_text_reveal(-1)
		return
	if line.responses.size()>0: return
	_show_next(_next)

func choose(index: int):
	if not active or loading or index<0 or index>=line.responses.size(): return
	branch_choice = line.responses[index].text
	mission.choice = index
	_show_next(line.responses[index].next_id)

func cancel():
	generation+=1
	active = false
	loading = false
	line=null
	resource=null
	mission.dialogue_locked = false
	mission.hud.hide_dialogue()
	for actor in [mission.player,mission.amu,mission.zhou]:
		actor.visual.end_conversation()
		actor.visual.look_enabled = false
		actor.visual.mode = "idle"
		if actor!=mission.player: actor.fixed_pose=""

func close(skipped := false):
	if not active: return
	var completed_key = key
	cancel()
	mission.player.locked = false
	mission.director.leave()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if skipped: mission.skipped_dialogues+=1
	finished.emit(completed_key)

func toggle_auto():
	automatic = not automatic
	mission.hud.set_auto(automatic)

func _unhandled_input(event):
	if not active or mission.paused: return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_SPACE,KEY_ENTER,KEY_E]:
			advance()
			get_viewport().set_input_as_handled()

func _process(delta):
	if not active or loading or not line or mission.paused: return
	visible_chars += delta*30.0
	mission.hud.set_text_reveal(-1 if fully_revealed else mini(int(visible_chars),line.text.length()))
	read_clock += delta
	# Reading time, not a mandatory gate: manual click, auto, choices and skip all work.
	if automatic and line.responses.is_empty() and visible_chars>=line.text.length() and read_clock>maxf(3.2,float(line.text.length())/5.3+1.0):
		_show_next(_next)
		return
	var speaker = mission.actor_by_name(line.character)
	var listener = mission.player if speaker!=mission.player else mission.dialogue_partner()
	for actor in [speaker,listener]:
		var other = listener if actor==speaker else speaker
		var difference = other.position-actor.position
		if difference.length()>.1:
			actor.rotation.y = lerp_angle(actor.rotation.y,Vector2(difference.z,difference.x).angle(),minf(delta*5,1))
