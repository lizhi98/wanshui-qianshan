extends "res://game/soldier_visual.gd"

var animation_tree: AnimationTree
var playback
var motion_space: AnimationNodeBlendSpace1D
var gesture := "talk"
var look_target := Vector3.ZERO
var look_enabled := false
var armed := false
var blink_clock := 1.0
var face_meshes: Array = []
var motion_speed := 0.0
var action_blend := 0.0
var upper_body_reload := false
var reload_blend := 0.0
var personality := 0
var animation_offset := 0.0
var conversation_role := 0 # 0 gameplay, 1 speaker, 2 listener
var conversation_time := 0.0
var conversation_beat := 0
var language_right := Vector3.ZERO
var language_left := Vector3.ZERO
var language_ready := false
var gaze_yaw := 0.0
var gaze_pitch := 0.0
var voice_active:=false
var climb_grips:Dictionary={}
var climb_travel:=0.0
var climb_origin_z:=0.0
var climb_previous_z:=0.0

func _actor_variant(actor_name:String)->String:
	return "zhou" if "zhou" in actor_name else ("amu" if "amu" in actor_name else "linchuan")
func _ready():
	var actor_name = str(get_parent().name).to_lower()
	var variant = _actor_variant(actor_name)
	personality=2 if variant=="zhou" else (1 if variant=="amu" else 0)
	animation_offset=[.32,1.17,2.06][personality]+float(abs(hash(actor_name))%11)*.03
	blink_clock=[.8,2.2,3.7][personality]
	rig = load(str(get_meta("rig_resource", "res://assets/remaster/characters/"+variant+".glb"))).instantiate()
	add_child(rig)
	skeleton = rig.find_children("*","Skeleton3D",true,false)[0]
	animator = rig.find_children("*","AnimationPlayer",true,false)[0]
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var library = animator.get_animation_library("")
	for clip in ["Idle","Walk","Sprint","Jump","Crouch_Fwd","Pistol_Idle","Jog_Fwd","Idle_Talking"]:
		if library.has_animation(clip):
			library.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			if not library.has_animation(clip+"_Loop"): library.add_animation(clip+"_Loop",library.get_animation(clip))
	for mesh in rig.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh.get_blend_shape_count()>0: face_meshes.append(mesh)
		if "defender" in actor_name and "Tunic" in str(mesh.name):
			var source = mesh.get_active_material(0)
			if source is StandardMaterial3D:
				var cloth = source.duplicate()
				cloth.albedo_color = Color("665d46")
				mesh.material_override = cloth
	carry_anchor = Node3D.new()
	carry_anchor.name = "CarryAnchor"
	add_child(carry_anchor)
	carry_anchor.position = Vector3(0,1.14,1.48)
	_make_rifle()
	_make_tree()
	load("res://game/v33/character_detail.gd").apply(self,variant)

func _clip(clip_name: String) -> AnimationNodeAnimation:
	var node = AnimationNodeAnimation.new()
	node.animation = clip_name if animator.has_animation(clip_name) else clip_name.trim_suffix("_Loop")
	return node

func _make_tree():
	animation_tree = AnimationTree.new()
	animation_tree.name = "CharacterAnimationTree"
	add_child(animation_tree)
	animation_tree.anim_player = animation_tree.get_path_to(animator)
	animation_tree.root_node = animation_tree.get_path_to(animator.get_node(animator.root_node))
	animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var graph = AnimationNodeBlendTree.new()
	motion_space = AnimationNodeBlendSpace1D.new()
	motion_space.min_space = 0
	motion_space.max_space = 5
	for entry in [["Idle_Loop",0.0],["Walk_Loop",1.8],["Jog_Fwd_Loop",3.2],["Sprint_Loop",4.8]]:
		motion_space.add_blend_point(_clip(entry[0]), entry[1], -1, entry[0])
	graph.add_node("Locomotion",motion_space,Vector2(0,0))
	graph.add_node("Aim",_clip("Pistol_Idle_Loop"),Vector2(0,180))
	var upper = AnimationNodeBlend2.new()
	upper.filter_enabled = true
	var sample = animator.get_animation("Idle_Loop")
	for i in sample.get_track_count():
		var path = sample.track_get_path(i)
		var bone = str(path).get_slice(":",1)
		if bone.begins_with("spine") or bone.begins_with("clavicle") or "arm" in bone or "hand" in bone or "head" in bone.to_lower() or bone.begins_with("neck") or bone.begins_with("thumb") or bone.begins_with("index") or bone.begins_with("middle") or bone.begins_with("ring") or bone.begins_with("pinky"):
			upper.set_filter_path(path,true)
	graph.add_node("UpperBody",upper,Vector2(260,60))
	graph.connect_node("UpperBody",0,"Locomotion")
	graph.connect_node("UpperBody",1,"Aim")
	var states = AnimationNodeStateMachine.new()
	# Conversation uses a quiet breathing base. Authored asymmetric hand targets
	# below provide each person's gestures instead of three copies of one talk loop.
	var clips = {"talk":"Idle_Loop","explain":"Idle_Loop","point":"Idle_Loop","concerned":"Idle_Loop","assure":"Idle_Loop","recall":"Idle_Loop","resolve":"Idle_Loop","pickup":"Fixing_Kneeling","place":"Fixing_Kneeling","brace":"Interact","reload":"Pistol_Reload","climb":"Idle_Loop","kneel_aim":"Crouch_Idle","dead":"Death01","hit":"Hit_Chest","jump":"Jump_Loop"}
	for key in clips:
		if key in ["pickup","place","brace"]:
			var work_pose=AnimationNodeBlendSpace1D.new()
			work_pose.min_space=.2
			work_pose.max_space=.8
			work_pose.add_blend_point(_clip("Fixing_Kneeling"), .2, -1, &"Fixing_Kneeling")
			work_pose.add_blend_point(_clip("Crouch_Idle"), .45, -1, &"Crouch_Idle")
			work_pose.add_blend_point(_clip("Idle_Loop"), .8, -1, &"Idle_Loop")
			states.add_node(key,work_pose)
		else: states.add_node(key,_clip(clips[key]))
	for from in clips:
		for to in clips:
			if from != to:
				var transition = AnimationNodeStateMachineTransition.new()
				transition.xfade_time = 0.24
				states.add_transition(from,to,transition)
	graph.add_node("Actions",states,Vector2(260,300))
	# The same upper-body mask preserves the locomotion hips and leg tracks.
	graph.add_node("Reload",_clip("Pistol_Reload"),Vector2(0,440))
	graph.add_node("ReloadSeek",AnimationNodeTimeSeek.new(),Vector2(260,440))
	graph.connect_node("ReloadSeek",0,"Reload")
	graph.add_node("ReloadBlend",upper.duplicate(),Vector2(480,180))
	graph.connect_node("ReloadBlend",0,"UpperBody")
	graph.connect_node("ReloadBlend",1,"ReloadSeek")
	graph.add_node("ActionBlend",AnimationNodeBlend2.new(),Vector2(520,80))
	graph.connect_node("ActionBlend",0,"ReloadBlend")
	graph.connect_node("ActionBlend",1,"Actions")
	graph.connect_node("output",0,"ActionBlend")
	animation_tree.tree_root = graph
	animation_tree.active = true
	playback = animation_tree.get("parameters/Actions/playback")
	playback.start("talk")

func _make_rifle():
	rifle = Node3D.new()
	add_child(rifle)
	box(rifle,Vector3(.052,.07,.70),Vector3(0,0,.08),Color("563b27"))
	box(rifle,Vector3(.035,.035,.91),Vector3(0,.04,.23),Color("252a2b"))
	box(rifle,Vector3(.06,.11,.07),Vector3(0,-.06,-.035),Color("222525"))
	muzzle = Node3D.new()
	rifle.add_child(muzzle)
	muzzle.position = Vector3(0,.04,.69)

func _process(delta):
	if not animation_tree: return
	var owner_mission=get_parent().get("mission")
	if owner_mission and owner_mission.get("paused")==true: return
	hand_error=0
	pose_time += delta
	action_time += delta
	hurt_time = maxf(0,hurt_time-delta)
	if last_mode != mode:
		pose_time = 0
		if upper_body_reload and mode=="reload":
			animation_tree.set("parameters/ReloadSeek/seek_request",0.0)
		if mode=="climb":
			climb_travel=0; climb_origin_z=global_position.z; climb_previous_z=global_position.z
		else: climb_grips.clear()
		last_mode = mode
	var action = mode
	if mode == "talk": action = gesture
	if hurt_time>0: action = "hit"
	var use_action = action in ["talk","explain","point","concerned","assure","recall","resolve","pickup","place","brace","reload","climb","kneel_aim","dead","hit","jump"]
	if use_action and playback.get_current_node()!=action: playback.travel(action)
	motion_speed = lerpf(motion_speed,speed,minf(delta*8,1))
	var layered_reload = upper_body_reload and action=="reload"
	reload_blend = move_toward(reload_blend,1.0 if layered_reload else 0.0,delta*8)
	action_blend = move_toward(action_blend,1.0 if use_action and not layered_reload else 0.0,delta*5)
	animation_tree.set("parameters/Locomotion/blend_position",motion_speed)
	animation_tree.set("parameters/UpperBody/blend_amount",1.0 if armed or mode=="aim" else 0.0)
	animation_tree.set("parameters/ActionBlend/blend_amount",action_blend)
	animation_tree.set("parameters/ReloadBlend/blend_amount",reload_blend)
	var work_height=.25
	if hand_targets.size()==2: work_height=clampf((to_local(hand_targets[0]).y+to_local(hand_targets[1]).y)*.5,.2,.8)
	for work in ["pickup","place","brace"]: animation_tree.set("parameters/Actions/"+work+"/blend_position",work_height)
	skeleton.clear_bones_global_pose_override()
	var pace=[.96,1.055,.91][personality] if speed<.1 else [1.0,1.035,.975][personality]
	animation_tree.advance(delta*pace+animation_offset)
	animation_offset=0
	skeleton.force_update_all_bone_transforms()
	rig.position.y=-.04+sin(climb_travel/.48*TAU*2)*.018 if mode=="climb" else 0.0
	rig.position.z=.09 if mode=="climb" else 0.0
	rig.rotation.x=.035 if mode=="climb" else 0.0
	rig.rotation.z=sin(climb_travel/.36*TAU)*.025 if mode=="climb" else 0.0
	if mode in ["pickup","place","brace"]: _bend_torso(.15)
	if conversation_role>0:
		conversation_time+=delta
		_conversation_posture()
	_head_look(delta)
	_face(delta)
	rifle.visible = armed and mode not in ["talk","pickup","place","brace","carry","climb","dead"]
	if rifle.visible:
		rifle.position = Vector3(-.06,.98 if mode=="kneel_aim" else 1.30,.16)
		_solve_arm("r",rifle.position+Vector3(0,0,-.09))
		_solve_arm("l",rifle.position+Vector3(.04,.01,.16))
	elif mode == "carry":
		carry_anchor.position.y = 1.14+sin(action_time*5)*.012
		_solve_arm("r",Vector3(-.30,1.13,.25))
		_solve_arm("l",Vector3(.30,1.13,.25))
	elif mode == "climb":
		_climb_pose()
	if hand_targets.size()==2:
		var first=to_local(hand_targets[0])
		var second=to_local(hand_targets[1])
		_solve_arm("r",first if first.x<second.x else second)
		_solve_arm("l",second if first.x<second.x else first)
	elif conversation_role>0 and mode in ["idle","talk"]:
		_conversation_hands(delta)
		_relax_conversation_fingers()

func _climb_pose():
	# Each grip stays on its chain link while the body advances. Only the
	# trailing hand releases and reaches to the next link; stopping freezes it.
	climb_travel+=climb_previous_z-global_position.z
	climb_previous_z=global_position.z
	var stride=.36
	for entry in [["r",0.0],["l",.5]]:
		var side:String=entry[0]; var offset:float=entry[1]
		var q=climb_travel/stride+offset; var phase=fposmod(q,1.0)
		var reach=smoothstep(.66,1.0,phase)
		var along=(floorf(q)-offset+reach)*stride+.12
		var side_sign=-1.0 if global_position.x<0 else 1.0
		var grip=Vector3(global_position.x+side_sign*.43,1.48+sin(reach*PI)*.075,climb_origin_z-along)
		climb_grips[side]=grip
		_solve_arm(side,to_local(grip))
		# The feet hook the lower chain in alternation with the opposite hand.
		var foot_q=climb_travel/stride+offset+.5
		var foot_phase=fposmod(foot_q,1.0); var foot_reach=smoothstep(.58,1,foot_phase)
		var foot_along=(floorf(foot_q)-offset-.5+foot_reach)*stride-.10
		var foot=Vector3(global_position.x+side_sign*.16,.08+sin(foot_reach*PI)*.17,climb_origin_z-foot_along)
		_solve_leg(side,to_local(foot))

func _solve_leg(side:String,target:Vector3):
	var upper=skeleton.find_bone("thigh_"+side); var lower=skeleton.find_bone("calf_"+side); var end=skeleton.find_bone("foot_"+side)
	if upper<0 or lower<0 or end<0: return
	var a=skeleton.get_bone_global_pose(upper); var b=skeleton.get_bone_global_pose(lower); var c=skeleton.get_bone_global_pose(end)
	var goal=skeleton.to_local(to_global(target)); var l1=a.origin.distance_to(b.origin); var l2=b.origin.distance_to(c.origin)
	var direction=(goal-a.origin).normalized(); var distance=clampf(goal.distance_to(a.origin),.06,l1+l2-.008)
	var along=(l1*l1-l2*l2+distance*distance)/(2*distance); var h=sqrt(maxf(0,l1*l1-along*along))
	var pole=Vector3(-.15 if side=="r" else .15,.1,1)
	var knee=a.origin+direction*along+(pole-direction*direction.dot(pole)).normalized()*h
	var ankle=a.origin+direction*distance
	a.basis=Basis(Quaternion((b.origin-a.origin).normalized(),(knee-a.origin).normalized()))*a.basis
	b.basis=Basis(Quaternion((c.origin-b.origin).normalized(),(ankle-knee).normalized()))*b.basis; b.origin=knee
	c.origin=ankle; c.basis=b.basis*skeleton.get_bone_global_rest(lower).basis.inverse()*skeleton.get_bone_global_rest(end).basis
	skeleton.set_bone_global_pose_override(upper,a,1,true); skeleton.set_bone_global_pose_override(lower,b,1,true); skeleton.set_bone_global_pose_override(end,c,1,true)

func _head_look(delta):
	var index = skeleton.find_bone("Head")
	var pose = skeleton.get_bone_global_pose(index)
	var yaw=0.0
	var pitch=0.0
	if look_enabled:
		var direction = skeleton.to_local(look_target)-pose.origin
		yaw = clampf(atan2(direction.x,direction.z),-.48,.48)
		pitch = clampf(-atan2(direction.y,Vector2(direction.x,direction.z).length()),-.18,.18)
	if conversation_role==2:
		var cycle=fmod(conversation_time+personality*2.7,8.8)
		if cycle>5.8 and cycle<6.8: pitch+=sin((cycle-5.8)*TAU)*.045
	var blend=1-exp(-delta*4)
	gaze_yaw=lerpf(gaze_yaw,yaw,blend)
	gaze_pitch=lerpf(gaze_pitch,pitch,blend)
	pose.basis = Basis(Vector3.UP,gaze_yaw)*Basis(Vector3.RIGHT,gaze_pitch)*pose.basis
	skeleton.set_bone_global_pose_override(index,pose,.7,true)

func set_conversation(speaking: bool,gesture_name: String,beat: int):
	conversation_role=1 if speaking else 2
	conversation_beat=beat
	conversation_time=personality*.19
	gesture=gesture_name
	mode="talk" if speaking else "idle"
	speed=0
	armed=false

func end_conversation():
	conversation_role=0
	language_ready=false
	mode="idle"

func _conversation_posture():
	var index=skeleton.find_bone("spine_01")
	var pose=skeleton.get_bone_global_pose(index)
	var tilt=[-.014,.018,-.007][personality]+sin(conversation_time*.67+personality)*.006
	pose.basis=Basis(Vector3.FORWARD,tilt)*pose.basis
	skeleton.set_bone_global_pose_override(index,pose,1.0,true)
	skeleton.force_update_all_bone_transforms()

func _conversation_hands(delta):
	var head_height=skeleton.get_bone_global_rest(skeleton.find_bone("Head")).origin.y
	var scale_factor=head_height/1.5594
	var right=Vector3(-.23,.89,.07)
	var left=Vector3(.22,.88,.05)
	match personality:
		1:
			right=Vector3(-.21,.93,.12)
			left=Vector3(.18,1.02,.13)
		2:
			right=Vector3(-.19,1.00,.14)
			left=Vector3(.22,.91,.06)
	if conversation_role==1:
		var period=[6.8,5.3,8.0][personality]
		var moment=fmod(conversation_time,period)
		var envelope=sin(PI*clampf(moment/2.9,0,1)) if moment<2.9 else 0.0
		var active_r=right
		var active_l=left
		match personality:
			0: active_r=Vector3(-.18,1.12,.29); active_l=Vector3(.20,.96,.12)
			1: active_r=Vector3(-.32,1.15,.33); active_l=Vector3(.28,1.20,.30)
			2: active_r=Vector3(-.22,1.22,.38); active_l=Vector3(.20,.94,.10)
		match gesture:
			"explain":
				active_r+=Vector3(-.035,.04,.055)
				if personality!=2: active_l+=Vector3(.015,.05,.06)
			"point":
				active_r=Vector3(-.35,1.34,.53)
				active_l=left
			"concerned", "recall":
				active_r=Vector3(-.065,1.25,.19)
				active_l=Vector3(.18,.96,.14)
			"assure":
				active_r=Vector3(-.16,1.18,.31)
				active_l=left
			"resolve":
				active_r=Vector3(-.11,1.12,.19)
				active_l=Vector3(.15,1.00,.16)
		# Alternate a secondary movement only for Amu; the other two keep one
		# hand quiet. A pause between phrases avoids continuous mechanical waving.
		if personality==1 and conversation_beat%2==1:
			active_l.y+=.06; active_r.y-=.04
		right=right.lerp(active_r,envelope)
		left=left.lerp(active_l,envelope)
	var base_right=to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("hand_r")).origin))
	var base_left=to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("hand_l")).origin))
	var breath=sin(conversation_time*(1.4+personality*.12)+personality)*.004
	right.y+=breath; left.y+=breath
	right*=scale_factor; left*=scale_factor
	if conversation_role==2:
		# Listening is mostly the original quiet idle, with no compulsory arm
		# pose. Only Amu occasionally adjusts the strap with one hand.
		right=base_right
		left=base_left
		if personality==1:
			var touch=sin(PI*clampf(fmod(conversation_time+conversation_beat,9.5)/3.2,0,1))
			left=left.lerp(Vector3(.14,1.28,.12)*scale_factor,touch*.65)
	elif personality!=1:
		left=base_left.lerp(left,.2 if personality==0 else .08)
	if not language_ready:
		language_right=to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("hand_r")).origin))
		language_left=to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("hand_l")).origin))
		language_ready=true
	var blend=1-exp(-delta*5.5)
	language_right=language_right.lerp(right,blend)
	language_left=language_left.lerp(left,blend)
	_solve_arm("r",language_right)
	_solve_arm("l",language_left)

func _relax_conversation_fingers():
	# UAL's neutral pose carries a strong fist curl. Retain part of that curl
	# while opening toward the rig's anatomical rest pose, after the arm IK.
	skeleton.force_update_all_bone_transforms()
	var updated:Dictionary={}
	for side in ["r","l"]:
		for finger in ["thumb","index","middle","ring","pinky"]:
			for joint in [1,2,3]:
				var index=skeleton.find_bone("%s_0%d_%s"%[finger,joint,side])
				if index<0: continue
				var parent=skeleton.get_bone_parent(index)
				var parent_pose:Transform3D=updated[parent] if updated.has(parent) else skeleton.get_bone_global_pose(parent)
				var rest=skeleton.get_bone_rest(index)
				var opening=.68 if conversation_role==1 else .54
				if finger=="thumb": opening=.40
				if gesture=="point" and conversation_role==1 and side=="r": opening=1.0 if finger=="index" else .25
				if gesture=="resolve" and conversation_role==1: opening=.28
				var finger_rotation=skeleton.get_bone_pose_rotation(index).slerp(Quaternion.IDENTITY,opening)
				var pose=Transform3D(parent_pose.basis*rest.basis*Basis(finger_rotation),parent_pose*rest.origin)
				skeleton.set_bone_global_pose_override(index,pose,1.0,true)
				updated[index]=pose

func _bend_torso(angle: float):
	# Keep procedural offsets in the override layer. Editing local pose rotations
	# would accumulate when AnimationTree skips an unchanged animation key.
	var index=skeleton.find_bone("spine_01")
	var global_pose=skeleton.get_bone_global_pose(index)
	global_pose.basis=Basis(Vector3.RIGHT,angle)*global_pose.basis
	skeleton.set_bone_global_pose_override(index,global_pose,1.0,true)
	skeleton.force_update_all_bone_transforms()

func _face(delta):
	blink_clock -= delta
	if blink_clock < -.16: blink_clock = randf_range(2.5,4.8)
	var blink = sin(clampf(-blink_clock/.16,0,1)*PI)
	for mesh in face_meshes:
		if mesh.mesh.get_blend_shape_count()>0: mesh.set_blend_shape_value(0,blink)
		if mesh.mesh.get_blend_shape_count()>1: mesh.set_blend_shape_value(1,(.12+absf(sin(action_time*13))*.20) if voice_active else (.12 if mode=="talk" else .0))

func play(_clip_name: String,_blend := .18):
	pass # Public compatibility for the inherited controller; AnimationTree owns playback.

func reset_pose():
	end_conversation()
	mode = "idle"
	hurt_time = 0
	hand_targets = []
	look_enabled = false
	armed = false
