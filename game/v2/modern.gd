extends "res://game/remaster/modern.gd"
var collected:Array[int]=[]
var classified:Array[int]=[]
var compared:=false
var feedback:=""
var evidence:Node3D
const NAMES=["九根底索","四根扶索","木板桥面"]
const SLOTS=[0,2,1]
func _ready():
	super._ready()
	evidence=Node3D.new(); evidence.name="ObservedStructure"; mission.add_child(evidence)
func start():
	collected.clear(); classified.clear(); scanned.clear(); compared=false; selected=0
	feedback="先到观察点采集，再判断高亮结构。"
	super.start()
	evidence.show()
	_show_evidence()
func select_point(index:int):
	super.select_point(index)
	_show_evidence()
func _show_evidence():
	if not evidence: return
	for child in evidence.get_children(): child.free()
	# Highlight exactly the physical structure the current camera is surveying.
	var mat=StandardMaterial3D.new(); mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=Color("f4c36e"); mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color.a=.62
	if selected<2:
		for i in (9 if selected==0 else 4):
			var line=MeshInstance3D.new(); var mesh=CylinderMesh.new(); mesh.top_radius=.045; mesh.bottom_radius=.045; mesh.height=78; mesh.radial_segments=8
			line.mesh=mesh; line.material_override=mat; line.rotation.x=PI/2
			line.position=Vector3(-1.6+i*.4,.08,-39) if selected==0 else Vector3(-1.86 if i<2 else 1.86,.84 if i%2==0 else 1.54,-39)
			evidence.add_child(line)
	else:
		for i in 40:
			var line=MeshInstance3D.new(); var mesh=BoxMesh.new(); mesh.size=Vector3(3.45,.06,.22)
			line.mesh=mesh; line.material_override=mat; line.position=Vector3(0,.17,-i*2); evidence.add_child(line)
func collect()->bool:
	if not active or selected in collected or position.distance_to(scan_points[selected])>3.2: return false
	collected.append(selected); mission.audio.dialogue_tick()
	feedback="证据已采集。根据高亮数量和位置判断结构。"
	mission.say("数字记录",feedback); mission.save_checkpoint(); return true
func classify(kind:int)->bool:
	if not active or not selected in collected or selected in scanned: return false
	if kind!=selected:
		feedback=["底索位于桥面下方，共九根。再观察高亮位置。","扶索分列左右，各两根。再数一数侧面的线。","横向木板连接底索，构成可通行桥面。"][selected]
		mission.say("判断提示",feedback); return false
	if not selected in classified: classified.append(selected)
	feedback="判断正确：%s。把它放入对应结构层。"%NAMES[selected]
	mission.say("数字记录",feedback); mission.save_checkpoint(); return true
func place_layer(slot:int)->bool:
	if not active or not selected in classified or selected in scanned: return false
	if slot!=SLOTS[selected]:
		feedback="层位不匹配。底索承载在下，木板通行在中，扶索位于两侧。"
		mission.say("组装提示",feedback); return false
	scanned.append(selected); _build_layers()
	feedback="%s已组装。继续采集，完成后切换历史对照。"%NAMES[selected]
	mission.say("数字记录",feedback); mission.save_checkpoint(); return true
func compare():
	super.compare(); compared=true; mission.save_checkpoint()
func ready_to_finish()->bool: return scanned.size()==3 and compared
func snapshot()->Dictionary:
	return {"collected":collected.duplicate(),"classified":classified.duplicate(),"placed":scanned.duplicate(),"compared":compared,"selected":selected}
func restore_snapshot(state:Dictionary):
	collected.clear(); classified.clear(); scanned.clear()
	for i in state.get("collected",[]):
		if int(i) in [0,1,2] and not int(i) in collected: collected.append(int(i))
	for i in state.get("classified",[]):
		if int(i) in collected and not int(i) in classified: classified.append(int(i))
	for i in state.get("placed",[]):
		if int(i) in classified and not int(i) in scanned: scanned.append(int(i))
	compared=bool(state.get("compared",false)); selected=clampi(int(state.get("selected",0)),0,2)
	_build_layers(); _show_evidence()
func stop():
	super.stop()
	if evidence: evidence.hide()
func _exit_tree():
	if is_instance_valid(evidence): evidence.queue_free()
