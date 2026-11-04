extends "res://game/remaster/character_visual.gd"
const P=preload("res://game/golden_hook/props.gd")
var posture:="standing"
var held:=""
var held_node:Node3D
var external_grip:=false
var contact=preload("res://game/golden_hook/contact_solver.gd").new()
var contact_profile:=""
var contact_prop:Node3D
var emotion:=""
var speaking:=false
var speech_energy:=0.0
var mouth_level:=0.0
var old_posture:="standing"
var held_id:=0
var ground_contact
var turning:=0.0
var previous_yaw:=0.0
var ground_origin_y:=0.0
var sole_offsets={"l":.086,"r":.086}
var collapse_clock:=0.0
func _ready():
	if "Qing" in str(get_parent().name): set_meta("rig_resource","res://assets/golden_hook/models/qing.glb")
	elif "Zhou_Elder" in str(get_parent().name): set_meta("rig_resource","res://assets/golden_hook/models/elder.glb")
	super._ready()
	contact.setup(skeleton)
	_calibrate_soles()
	ground_contact=load("res://game/memorial/contact_ik.gd").new(); ground_contact.setup(self)
	rifle.hide(); armed=false
	var parent_name=str(get_parent().name).to_lower()
	var tint="676953" if "zhou" in parent_name else ("707b71" if "amu" in parent_name else "64736e")
	for mesh in rig.find_children("*","MeshInstance3D",true,false):
		if "Tunic" in str(mesh.name) or "Trousers" in str(mesh.name):
			var source=mesh.get_active_material(0)
			if source is ShaderMaterial:
				var cloth=source.duplicate();cloth.set_shader_parameter("cloth_color",Color(tint));mesh.material_override=cloth
			if source is StandardMaterial3D:
				var cloth=source.duplicate(); cloth.albedo_color=Color(tint); mesh.material_override=cloth
	if parent_name.begins_with("distant"): return
	var eye_center=Vector3(0,1.60,.132)
	for mesh in rig.find_children("*","MeshInstance3D",true,false):
		if "high-poly" in str(mesh.name): eye_center=mesh.get_aabb().get_center()
	for mesh in face_meshes:
		preload("res://game/golden_hook/face_driver.gd").add_speech(mesh,eye_center)
		var original=mesh.get_active_material(0)
		if original is StandardMaterial3D and original.albedo_texture:
			var skin=ShaderMaterial.new(); skin.shader=load("res://game/golden_hook/skin.gdshader"); skin.set_shader_parameter("skin_texture",original.albedo_texture); skin.set_shader_parameter("eye_center",eye_center); skin.set_shader_parameter("age",.85 if "zhou" in parent_name else .05)
			mesh.material_override=skin
func _make_tree():
	super._make_tree()
	var states=animation_tree.tree_root.get_node("Actions")
	var sit=animator.get_animation("Sitting_Idle"); sit.loop_mode=Animation.LOOP_LINEAR
	# Reuse an existing action slot through a chapter-specific AnimationTree.
	# The shared remaster graph and its original chapter remain untouched.
	var sitting=AnimationNodeStateMachine.new();sitting.add_node("Enter",_clip("Sitting_Enter"));sitting.add_node("Hold",_clip("Sitting_Idle"))
	var begin=AnimationNodeStateMachineTransition.new();begin.advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO;sitting.add_transition("Start","Enter",begin)
	var settle=AnimationNodeStateMachineTransition.new();settle.advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO;settle.switch_mode=AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END;settle.xfade_time=.15;sitting.add_transition("Enter","Hold",settle)
	states.replace_node("recall",sitting);states.replace_node("resolve",_clip("Sitting_Exit"))
	var source=animator.get_animation("Fixing_Kneeling")
	var held_pose=Animation.new(); held_pose.length=1; held_pose.loop_mode=Animation.LOOP_LINEAR
	for track in source.get_track_count():
		var kind=source.track_get_type(track)
		if kind not in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D]: continue
		var target=held_pose.add_track(kind); held_pose.track_set_path(target,source.track_get_path(track))
		var sample=1.25
		var value: Variant
		match kind:
			Animation.TYPE_POSITION_3D: value = source.position_track_interpolate(track, sample)
			Animation.TYPE_ROTATION_3D: value = source.rotation_track_interpolate(track, sample)
			Animation.TYPE_SCALE_3D: value = source.scale_track_interpolate(track, sample)
		held_pose.track_insert_key(target,0,value)
	animator.get_animation_library("").add_animation("Grass_Kneel_Hold",held_pose)
	for key in ["pickup","place","brace"]:
		var blend=states.get_node(key); blend.set_blend_point_node(0,_clip("Grass_Kneel_Hold"))
	var graph=animation_tree.tree_root
	graph.disconnect_node("UpperBody",0); graph.add_node("LocomotionRate",AnimationNodeTimeScale.new()); graph.connect_node("LocomotionRate",0,"Locomotion"); graph.connect_node("UpperBody",0,"LocomotionRate")
func _process(delta):
	if not skeleton: return
	var owner_actor=get_parent()
	if owner_actor.get("mission") and owner_actor.mission.paused: return
	armed=false
	if posture=="seated":
		if old_posture!="seated":animation_tree.get("parameters/Actions/recall/playback").start("Enter",true)
		mode="talk";gesture="recall";speed=0
	elif posture=="rising":mode="talk";gesture="resolve";speed=0
	elif posture=="kneel": mode="pickup"; speed=0
	elif posture=="collapsed":
		mode="dead"; speed=0; look_enabled=false; conversation_role=0; gaze_yaw=0; gaze_pitch=0
		if not _can_whisper(): speech_energy=0; mouth_level=0
	elif old_posture in ["kneel","seated","collapsed"] and old_posture!=posture: mode="idle"
	old_posture=posture
	collapse_clock=collapse_clock+delta if posture=="collapsed" else 0.0
	turning=absf(angle_difference(previous_yaw,owner_actor.rotation.y))/maxf(delta,.0001); previous_yaw=owner_actor.rotation.y
	var measured=speed
	var running=measured>2.3
	var rate=clampf(measured/3.8,.65,1.25) if running else clampf(measured/.95,.35,2.15)
	if measured<.1: rate=.65 if turning>.2 else 1.0
	animation_tree.set("parameters/LocomotionRate/scale",rate)
	if posture in ["standing","weak"] and mode in ["idle","walk","run"]: speed=3.2 if running else (1.8 if measured>.1 or turning>.2 else 0.0)
	if held_node and not external_grip:
		var h=.48 if posture=="kneel" else (.61 if posture=="seated" else 1.05)
		var goal=Vector3(-.015,h,.34)
		if held_id!=held_node.get_instance_id(): held_node.position=goal; held_id=held_node.get_instance_id()
		else: held_node.position=held_node.position.lerp(goal,1-exp(-delta*14))
		hand_targets=contact.targets(held,held_node)
	elif external_grip and is_instance_valid(contact_prop): hand_targets=contact.targets(contact_profile,contact_prop)
	super._process(0.0 if posture=="collapsed" and collapse_clock>2.3 else delta)
	speed=measured
	rifle.hide()
	if posture=="seated": _settle_feet()
	if posture=="weak" and mode in ["walk","idle"]: _bend_torso(.095 if "Zhou" in str(owner_actor.name) else .055)
	for mesh in rig.find_children("*","MeshInstance3D",true,false):
		if "Canvas_backpack" in str(mesh.name) or "Rolled_blanket" in str(mesh.name):mesh.visible=posture!="collapsed"
	if posture=="collapsed": _resting_arms()
	elif posture in ["standing","weak"] and mode not in ["jump","pickup","place","brace"]: ground_contact.tick(delta)
	# The pinching hand is semantic: rotating the needle across the body must
	# not swap its right-hand target with the supporting left hand.
	if external_grip and contact_profile in ["hook","ladle"] and is_instance_valid(contact_prop):
		var targets=contact.targets(contact_profile,contact_prop)
		_solve_arm("r",to_local(targets[0]));_solve_arm("l",to_local(targets[1]))
	if is_instance_valid(held_node) and not external_grip: contact.apply(held,held_node,delta)
	elif is_instance_valid(contact_prop): contact.apply(contact_profile,contact_prop,delta)
func set_contact(profile:String,prop:Node3D): contact_profile=profile; contact_prop=prop
func set_emotion(mood:String,is_speaking:bool): emotion=mood; speaking=is_speaking
func release_emotion(): emotion=""; speaking=false; speech_energy=0
func _can_whisper()->bool:
	var actor=get_parent()
	return "Zhou" in str(actor.name) and actor.get("mission") and actor.mission.story.elder_fate=="alive" and speaking
func hold(kind:String):
	if held==kind: return
	if is_instance_valid(held_node): held_node.queue_free()
	held_node=null; held=kind; hand_targets=[]; external_grip=false
	if kind=="bowl": held_node=P.bowl(self,true)
	elif kind=="greens": held_node=P.greens(self,Vector3.ZERO)
	elif kind=="scraps":
		held_node=P.bowl(self,false)
		var root_mat=P.mat("75664b"); var bone_mat=P.mat("c6c4a6")
		for i in 4:
			P.polyline(held_node,PackedVector3Array([Vector3(-.07,.075,(i-1.5)*.025),Vector3(0,.09,(i-1.5)*.025+.01),Vector3(.06,.08,(i-1.5)*.025-.01)]),.006,root_mat)
		P.cylinder(held_node,Vector3(-.07,.10,0),Vector3(.07,.10,.025),.003,bone_mat)
		for i in 5:
			var x=-.05+i*.025
			P.cylinder(held_node,Vector3(x,.103,.01),Vector3(x+.015,.11,.05),.002,bone_mat)
			P.cylinder(held_node,Vector3(x,.103,.01),Vector3(x+.015,.11,-.04),.002,bone_mat)
	elif kind=="hook":
		held_node=P.hook(self,1,true); held_node.scale=Vector3.ONE*1.3
	elif kind=="parcel": held_node=P.parcel(self)
func reset_pose():
	super.reset_pose()
	posture="standing"; hold(""); external_grip=false; contact.clear(); contact_profile=""; contact_prop=null; release_emotion()
	collapse_clock=0; ground_origin_y=0
	if ground_contact: ground_contact.reset(true)
func restore_posture(value:String):
	posture=value;old_posture=value
	if value not in ["collapsed","seated"]:return
	animation_offset=0;action_blend=1.0
	animation_tree.set("parameters/ActionBlend/blend_amount",1.0)
	if value=="collapsed":
		mode="dead";playback.start("dead",true);animation_tree.advance(animator.get_animation("Death01").length);collapse_clock=2.4;_resting_arms();_face(0)
	else:
		mode="talk";gesture="recall";playback.start("recall",true);animation_tree.get("parameters/Actions/recall/playback").start("Hold",true);animation_tree.advance(0);_settle_feet()
func _calibrate_soles():
	var sole_y=INF
	for mesh in rig.find_children("*shoes*","MeshInstance3D",true,false):
		var model=global_transform.affine_inverse()*mesh.global_transform
		for p in mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]: sole_y=minf(sole_y,(model*p).y)
	if sole_y==INF: return
	for side in ["l","r"]:
		var ankle=to_local(skeleton.to_global(skeleton.get_bone_global_rest(skeleton.find_bone("foot_"+side)).origin))
		sole_offsets[side]=clampf(ankle.y-sole_y,.04,.14)
func sole_offset(side:String)->float: return sole_offsets.get(side,.086)
func _resting_arms():
	var chest=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("spine_03")).origin)
	var pelvis=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("pelvis")).origin)
	var along=(pelvis-chest).normalized(); var lateral=get_parent().global_basis.x.normalized()
	var weight=smoothstep(.35,1.45,collapse_clock)
	for side in ["r","l"]:
		var raw=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("hand_"+side)).origin)
		var target=chest+along*(.19 if side=="r" else .08)+lateral*(-.08 if side=="r" else .14)+Vector3.UP*.065
		_solve_arm(side,to_local(raw.lerp(target,weight)))
	_relax_conversation_fingers()
func _settle_feet():
	var owner_actor=get_parent()
	if not owner_actor.get("mission"): return
	var terrain=owner_actor.mission.world
	for side in ["r","l"]:
		var hip=skeleton.find_bone("thigh_"+side); var knee=skeleton.find_bone("calf_"+side); var ankle=skeleton.find_bone("foot_"+side)
		var a=skeleton.get_bone_global_pose(hip); var b=skeleton.get_bone_global_pose(knee); var c=skeleton.get_bone_global_pose(ankle)
		var world_foot=skeleton.to_global(c.origin); world_foot.y=terrain.height_at(world_foot)+.043
		var goal=skeleton.to_local(world_foot)
		var l1=a.origin.distance_to(b.origin); var l2=b.origin.distance_to(c.origin)
		var direction=(goal-a.origin).normalized(); var distance=clampf(goal.distance_to(a.origin),.06,l1+l2-.005)
		var along=(l1*l1-l2*l2+distance*distance)/(2*distance); var height=sqrt(maxf(0,l1*l1-along*along))
		var pole=Vector3(0,0,1); var bend=(pole-direction*direction.dot(pole)).normalized()
		var joint=a.origin+direction*along+bend*height; var foot=a.origin+direction*distance
		a.basis=Basis(Quaternion((b.origin-a.origin).normalized(),(joint-a.origin).normalized()))*a.basis
		b.basis=Basis(Quaternion((c.origin-b.origin).normalized(),(foot-joint).normalized()))*b.basis; b.origin=joint; c.origin=foot
		skeleton.set_bone_global_pose_override(hip,a,1,true); skeleton.set_bone_global_pose_override(knee,b,1,true); skeleton.set_bone_global_pose_override(ankle,c,1,true)
func _face(delta):
	super._face(delta)
	var weak="微弱" in emotion or "气息" in emotion or "渐弱" in emotion
	var sad="悲" in emotion or "低声" in emotion or "担" in emotion or "哽" in emotion
	var whisper=_can_whisper() and posture=="collapsed"
	mouth_level=lerpf(mouth_level,speech_energy if speaking and (posture!="collapsed" or whisper) else 0.0,1-exp(-delta*20))
	for mesh in face_meshes:
		var blink=mesh.get_blend_shape_value(0)
		mesh.set_blend_shape_value(0,(.88 if whisper else 1.0) if posture=="collapsed" else maxf(blink,.25 if weak else (.09 if sad else .0)))
		if mesh.mesh.get_blend_shape_count()>1: mesh.set_blend_shape_value(1,.52 if sad else (.25 if weak else .08))
		var mouth=mesh.find_blend_shape_by_name("Grass_Speech")
		if mouth>=0: mesh.set_blend_shape_value(mouth,(mouth_level*.23 if whisper else 0.0) if posture=="collapsed" else mouth_level*.62)
