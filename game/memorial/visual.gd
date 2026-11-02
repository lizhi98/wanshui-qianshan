extends "res://game/remaster/character_visual.gd"
var narrative_pose:=""
var narrative_clock:=0.0
var coat:Node3D
var coat_received:=false
var recognizable_bag:Node3D
var snow_layer:Node3D
var snow_hat:Node3D
var seated_bag:Node3D
var dust_materials:Array=[]
var lod_clock:=0.0
var seated_frozen:=false
var layer_dirty:=false
var turning:=0.0
var ground_origin_y:=0.0
var sole_offsets={"l":.086,"r":.086}
var active_owner:="Idle"
var owner_history:Array=[]
var contact_driver
var previous_mode:="idle"
var transition_from:Dictionary={}
var recovery_base:Dictionary={}
var recovery_clock:=1.0
var recovery_duration:=.28
var recover_requested:=false
var recover_full_body:=false
var previous_run_motion:=false
const Props=preload("res://game/memorial/props.gd")
func _actor_variant(actor_name:String)->String:
	if "commander" in actor_name:return "linchuan"
	return super._actor_variant(actor_name)
func _ready():
	super._ready()
	_calibrate_soles()
	contact_driver=load("res://game/memorial/contact_ik.gd").new();contact_driver.setup(self)
	var actor_name=str(get_parent().name);var tint=Color("596b68").lerp(Color("80795e"),float(abs(hash(actor_name))%7)/12)
	if "Quartermaster" in actor_name:tint=Color("686b5f")
	for mesh in rig.find_children("*","MeshInstance3D",true,false):
		if mesh.skin:mesh.skin=mesh.skin.duplicate()
		mesh.visibility_range_end=75
		if mesh.material_override is ShaderMaterial and ("Tailored" in str(mesh.name) or "Tunic" in str(mesh.name) or "Fitted" in str(mesh.name)):
			var m=mesh.material_override.duplicate();m.set_shader_parameter("cloth_color",tint);mesh.material_override=m
	coat=_attachment("spine_03",Vector3(0,1.15,0))
	var cloth=CapsuleMesh.new();cloth.radius=.275;cloth.height=.69;cloth.radial_segments=18;cloth.rings=6
	var torso=Props.mesh(coat,cloth,Vector3.ZERO,Color("53604c"));torso.scale.z=.62
	for x in [-.16,-.08,0,.08,.16]:Props.box(coat,Vector3(.005,.48,.007),Vector3(x,.01,.17),Color("68725a"))
	coat.hide()
	if "Quartermaster" in actor_name or "Commander" in actor_name:
		for attachment in skeleton.find_children("PackWebbingAndBuckles","BoneAttachment3D",true,false):attachment.hide()
	if "Commander" in actor_name:
		var collar=_attachment("spine_03",Vector3(0,1.43,.04))
		Props.box(collar,Vector3(.24,.10,.11),Vector3.ZERO,Color("3d4a42"))
		var case=_attachment("spine_03",Vector3(.29,.91,.04))
		Props.box(case,Vector3(.22,.31,.10),Vector3.ZERO,Color("4f3928"))
		Props.box(case,Vector3(.18,.06,.015),Vector3(0,.10,.06),Color("80623e"))
		for mesh in rig.find_children("*","MeshInstance3D",true,false):
			if "Canvas_backpack" in str(mesh.name) or "Rolled_blanket" in str(mesh.name):mesh.hide()
			if mesh.material_override is ShaderMaterial:mesh.material_override.set_shader_parameter("cloth_color",Color("414f48"))

	if "Quartermaster" in actor_name:
		for mesh in rig.find_children("*","MeshInstance3D",true,false):
			if "Canvas_backpack" in str(mesh.name) or "Rolled_blanket" in str(mesh.name) or "Shoulder_strap" in str(mesh.name):mesh.hide()
		recognizable_bag=_attachment("spine_03",Vector3(.29,.87,-.05))
		var bag=Props.box(recognizable_bag,Vector3(.23,.28,.12),Vector3.ZERO,Color("574332"))
		Props.box(recognizable_bag,Vector3(.15,.09,.008),Vector3(0,.035,.065),Color("9b7a4d"))
		var hat=_attachment("Head",Vector3(-.065,1.65,.085));Props.box(hat,Vector3(.065,.03,.006),Vector3.ZERO,Color("ad9975"))
		snow_layer=_attachment("spine_03",Vector3(0,1.46,-.025))
		for x in [-.20,.20]:
			var snow=SphereMesh.new();snow.radius=.045;snow.height=.008;snow.radial_segments=12;snow.rings=4
			Props.mesh(snow_layer,snow,Vector3(x,0,0),Color("bfc9ca"))
		snow_layer.hide()
		snow_hat=_attachment("Head",Vector3(0,1.73,.015));var cap_snow=SphereMesh.new();cap_snow.radius=.11;cap_snow.height=.008;cap_snow.radial_segments=14;cap_snow.rings=4;Props.mesh(snow_hat,cap_snow,Vector3.ZERO,Color("c6cfd0"));snow_hat.hide()
		seated_bag=Node3D.new();add_child(seated_bag);seated_bag.position=Vector3(.34,.12,-.06);Props.box(seated_bag,Vector3(.23,.21,.12),Vector3.ZERO,Color("574332"));seated_bag.hide()
		for mesh in rig.find_children("*","MeshInstance3D",true,false):
			if mesh.material_override is ShaderMaterial and ("Tailored" in str(mesh.name) or "Tunic" in str(mesh.name)):
				var m=mesh.material_override.duplicate();m.shader=load("res://game/memorial/dusted_cloth.gdshader");mesh.material_override=m;dust_materials.append(m)

	if "Guard" in actor_name:
		for mesh in rig.find_children("*","MeshInstance3D",true,false):
			if "Canvas_backpack" in str(mesh.name) or "Rolled_blanket" in str(mesh.name):mesh.hide()
			if mesh.material_override is ShaderMaterial:
				mesh.material_override=mesh.material_override.duplicate();mesh.material_override.set_shader_parameter("cloth_color",Color("758482"))
		var bag=_attachment("spine_03",Vector3(-.29,.88,.02))
		Props.box(bag,Vector3(.20,.24,.09),Vector3.ZERO,Color("79745b"))
func _make_tree():
	var library=animator.get_animation_library("")
	if not animator.has_animation("Memorial_Clear_Loop"):
		var clip=animator.get_animation("Push" if animator.has_animation("Push") else "Interact").duplicate()
		clip.loop_mode=Animation.LOOP_LINEAR;library.add_animation("Memorial_Clear_Loop",clip)
	super._make_tree()
	var graph=animation_tree.tree_root
	graph.disconnect_node("UpperBody",0);graph.add_node("LocomotionRate",AnimationNodeTimeScale.new());graph.connect_node("LocomotionRate",0,"Locomotion");graph.connect_node("UpperBody",0,"LocomotionRate")
	var actions=animation_tree.tree_root.get_node("Actions")
	actions.get_node("dead").animation="Sitting_Idle_Loop" if animator.has_animation("Sitting_Idle_Loop") else "Sitting_Idle"
	actions.get_node("reload").animation="PickUp_Table"
	actions.get_node("hit").animation="Memorial_Clear_Loop"
func _attachment(bone:String,point:Vector3)->Node3D:
	var a=BoneAttachment3D.new();skeleton.add_child(a);a.bone_name=bone
	var n=Node3D.new();a.add_child(n);n.transform=skeleton.get_bone_global_rest(skeleton.find_bone(bone)).affine_inverse()*Transform3D(Basis.IDENTITY,point);return n
func set_coat(value:bool):
	coat_received=value
	if coat:coat.visible=value
func pose(value:String):
	if narrative_pose!=value:
		recover_requested=true;recover_full_body=value in ["seated","take","clear","inspect"] or narrative_pose in ["take","clear","inspect"];narrative_pose=value;narrative_clock=0;seated_frozen=false;layer_dirty=true
	if snow_layer and value!="seated":snow_layer.hide()
	if snow_hat and value!="seated":snow_hat.hide()
func _process(delta):
	if recognizable_bag:recognizable_bag.visible=narrative_pose!="seated"
	if seated_bag:seated_bag.visible=narrative_pose=="seated"
	for m in dust_materials:m.set_shader_parameter("snow_dusting",.32 if narrative_pose=="seated" else 0.0)
	if narrative_pose=="seated" and seated_frozen:return
	lod_clock+=delta
	var owner=get_parent();var m=owner.mission
	if m and m.view and m.view.camera.global_position.distance_to(global_position)>80:
		if lod_clock<.16:return
		delta=lod_clock
	lod_clock=0
	if not recover_requested and narrative_pose=="" and previous_mode!=mode and (previous_mode in ["carry","aim","reload"] or mode in ["carry","aim","reload"]):
		layer_dirty=true;recover_requested=true;recover_full_body=false
	var entering_run=speed>2.3 and mode not in ["carry","aim"]
	if not recover_requested and entering_run!=previous_run_motion:recover_requested=true;recover_full_body=false
	previous_run_motion=entering_run
	if recover_requested:_capture_recovery(recover_full_body);recover_requested=false
	previous_mode=mode
	if layer_dirty:
		skeleton.clear_bones_global_pose_override();skeleton.reset_bone_poses();layer_dirty=false
		if contact_driver:contact_driver.reset()
	if narrative_pose=="seated":mode="dead"
	elif narrative_pose=="take":mode="reload"
	elif narrative_pose=="clear":mode="hit"
	var measured_speed=speed
	var run_motion=measured_speed>2.3 and mode not in ["carry","aim"]
	var rate=clampf(measured_speed/.95,.35,2.15) if not run_motion else clampf(measured_speed/3.8,.65,1.25)
	if measured_speed<.10:rate=.65 if turning>.20 else 1.0
	animation_tree.set("parameters/LocomotionRate/scale",rate)
	# Select a complete authored clip; walk/run do not free-run at unrelated phases.
	speed=3.2 if run_motion else 1.8 if measured_speed>.10 or turning>.20 else 0.0
	super._process(0.0 if narrative_pose=="seated" and narrative_clock>1.2 else delta)
	speed=measured_speed
	if not skeleton or (get_parent().mission and get_parent().mission.paused):return
	narrative_clock+=delta
	var desired_origin=0.0
	if owner.has_method("get_floor_normal") and owner.is_on_floor():
		var ny=maxf(.65,owner.get_floor_normal().y);var radius=.27 if str(owner.name)=="Player" else .29
		desired_origin=-radius*(1.0/ny-1.0)
	ground_origin_y=move_toward(ground_origin_y,desired_origin,delta*1.2)
	if narrative_pose!="seated":rig.position.y=ground_origin_y
	var owner_name=narrative_pose.capitalize() if narrative_pose!="" else ("Carry" if mode=="carry" else "Aim" if mode=="aim" else "Run" if mode=="run" else "Walk" if speed>.15 else "Stop" if motion_speed>.18 else "Idle")
	if narrative_pose=="" and get_parent().get("motion_state")!=null:owner_name=get_parent().motion_state
	if owner_name!=active_owner:
		owner_history.append({"time":Time.get_ticks_msec()/1000.0,"from":active_owner,"to":owner_name});active_owner=owner_name
	match narrative_pose:
		"seated":
			rig.position.y=-.49*smoothstep(0,.75,narrative_clock);_bend_torso(.18);_solve_leg("l",Vector3(.19,sole_offset("l"),.50));_solve_leg("r",Vector3(-.16,sole_offset("r"),.58));_solve_arm("r",Vector3(-.17,.23,.23));_solve_arm("l",Vector3(.16,.19,.26))
			var head=skeleton.find_bone("Head");var head_pose=skeleton.get_bone_global_pose(head);head_pose.basis=Basis(Vector3.RIGHT,.30)*head_pose.basis;skeleton.set_bone_global_pose_override(head,head_pose,1,true)
			for face in face_meshes:
				if face.mesh.get_blend_shape_count()>0:face.set_blend_shape_value(0,smoothstep(.6,1.5,narrative_clock))
				if face.mesh.get_blend_shape_count()>1:face.set_blend_shape_value(1,0)
			if narrative_clock>1.5:seated_frozen=true
			if snow_layer:snow_layer.show()
			if snow_hat:snow_hat.show()
		"salute":
			var rise=smoothstep(.5,2.6,narrative_clock)*(1-smoothstep(6.8,8.8,narrative_clock))
			_solve_arm("r",Vector3(-.30,.90,.08).lerp(Vector3(-.24,1.54,.18),rise));_solve_arm("l",Vector3(.28,.88,.05))
			_solve_leg("l",Vector3(.11,.055,.04));_solve_leg("r",Vector3(-.11,.055,.04))
			if rise>.8:_salute_hand()
		"inspect":
			_bend_torso(.12)
		"report","identity_reply":
			_bend_torso(.04)
			_solve_arm("r",Vector3(-.24,1.04,.24 if voice_active else .13));_solve_arm("l",Vector3(.27,.89,.10))
		"handover":
			var reach=smoothstep(.2,1.7,narrative_clock)*(1-smoothstep(3.4,4.5,narrative_clock))
			_solve_arm("r",Vector3(-.27,1.04,.18+reach*.34));_solve_arm("l",Vector3(.27,1.04,.18+reach*.34))
		"shiver":_bend_torso(.10);_solve_arm("r",Vector3(.09,1.20,.18));_solve_arm("l",Vector3(-.09,1.04,.20))
		"anger","demand":
			var strength=smoothstep(0,1.1,narrative_clock)
			_bend_torso(.07*strength);_solve_arm("r",Vector3(-.32,1.12,.43*strength));_solve_arm("l",Vector3(.28,.93,.16))
			for stem in ["index","middle","ring","pinky"]:
				for number in ["01","02","03"]:
					var bone=skeleton.find_bone(stem+"_"+number+"_r")
					if bone>=0:skeleton.set_bone_pose_rotation(bone,skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()*Quaternion(Vector3.RIGHT,(1.25 if number=="01" else 1.55 if number=="02" else .95)*strength))
		"shock","lowered","witness","hesitate","concern":
			var amount=smoothstep(0,2,narrative_clock)
			_bend_torso((.06 if narrative_pose=="concern" else .025)*amount)
			_solve_arm("r",Vector3(-.27,.90,.13));_solve_arm("l",Vector3(.27,.88,.12))
		"pack":_solve_arm("r",Vector3(-.25,1.34,-.18));_solve_arm("l",Vector3(.30,1.15,.05))

	_apply_recovery(delta)
	# Store the evaluated animation/action layer before terrain IK. A transition
	# must not capture terrain pelvis offsets and apply those offsets a second time.
	var model_from_skeleton=global_transform.affine_inverse()*skeleton.global_transform
	recovery_base.clear()
	for i in skeleton.get_bone_count():recovery_base[i]=model_from_skeleton*skeleton.get_bone_global_pose(i)
	if contact_driver and narrative_pose not in ["seated","inspect"] and mode not in ["dead","jump","pickup"]:
		contact_driver.tick(delta)
	skeleton.force_update_all_bone_transforms()

func reset_pose():
	super.reset_pose();narrative_pose="";narrative_clock=0;seated_frozen=false;layer_dirty=true;active_owner="Idle";recover_requested=false;transition_from.clear();recovery_clock=1.0;ground_origin_y=0
	if contact_driver:contact_driver.reset(true)
	recovery_base.clear()
	if rig:rig.position=Vector3.ZERO
	if skeleton:skeleton.clear_bones_global_pose_override();skeleton.reset_bone_poses()

func _salute_hand():
	var h=skeleton.find_bone("hand_r");var finger=skeleton.find_bone("index_01_r")
	if h<0 or finger<0:return
	var pose_hand=skeleton.get_bone_global_pose(h)
	var axis=(skeleton.get_bone_global_pose(finger).origin-pose_hand.origin).normalized()
	pose_hand.basis=Basis(Quaternion(axis,Vector3(.9,.40,0).normalized()))*pose_hand.basis
	skeleton.set_bone_global_pose_override(h,pose_hand,1,true)
	for stem in ["index","middle","ring","pinky"]:
		for number in ["01","02","03"]:
			var bone=skeleton.find_bone(stem+"_"+number+"_r")
			if bone>=0:skeleton.set_bone_pose_rotation(bone,skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()*Quaternion(Vector3.RIGHT,.025))


func _solve_arm(side: String, target: Vector3):
	var upper = skeleton.find_bone("upperarm_"+side)
	var lower = skeleton.find_bone("lowerarm_"+side)
	var hand = skeleton.find_bone("hand_"+side)
	if upper < 0 or lower < 0 or hand < 0:
		return
	var a = skeleton.get_bone_global_pose(upper)
	var b = skeleton.get_bone_global_pose(lower)
	var c = skeleton.get_bone_global_pose(hand)
	var goal = skeleton.to_local(to_global(target))
	var l1 = a.origin.distance_to(b.origin)
	var l2 = b.origin.distance_to(c.origin)
	var direction = (goal-a.origin).normalized()
	var distance = clampf(goal.distance_to(a.origin), 0.06, l1+l2-0.008)
	var along = (l1*l1-l2*l2+distance*distance)/(2.0*distance)
	var height = sqrt(maxf(0.0, l1*l1-along*along))
	var pole = Vector3(-1 if side == "r" else 1, -0.65, -0.3)
	var bend = (pole-direction*direction.dot(pole)).normalized()
	var elbow = a.origin+direction*along+bend*height
	var wrist = a.origin+direction*distance
	var qa = Quaternion((b.origin-a.origin).normalized(), (elbow-a.origin).normalized())
	a.basis = Basis(qa)*a.basis
	var qb = Quaternion((c.origin-b.origin).normalized(), (wrist-elbow).normalized())
	b.basis = Basis(qb)*b.basis
	b.origin = elbow
	c.origin = wrist
	c.basis = b.basis * skeleton.get_bone_global_rest(lower).basis.inverse() * skeleton.get_bone_global_rest(hand).basis
	var parent=skeleton.get_bone_parent(upper)
	var parent_basis=skeleton.get_bone_global_pose(parent).basis
	skeleton.set_bone_pose_rotation(upper,(parent_basis.inverse()*a.basis).orthonormalized().get_rotation_quaternion())
	skeleton.set_bone_pose_rotation(lower,(a.basis.inverse()*b.basis).orthonormalized().get_rotation_quaternion())
	skeleton.set_bone_pose_rotation(hand,(b.basis.inverse()*c.basis).orthonormalized().get_rotation_quaternion())
	skeleton.force_update_all_bone_transforms()

func _capture_recovery(full_body:bool):
	transition_from.clear();recovery_clock=0;recovery_duration=.75 if full_body else .28
	var model_from_skeleton=global_transform.affine_inverse()*skeleton.global_transform
	for i in skeleton.get_bone_count():
		var name=skeleton.get_bone_name(i).to_lower()
		if full_body or name.begins_with("spine") or name.begins_with("clavicle") or "arm" in name or "hand" in name or name.begins_with("neck") or name=="head" or name.begins_with("index") or name.begins_with("middle") or name.begins_with("ring") or name.begins_with("pinky") or name.begins_with("thumb"):
			transition_from[i]=recovery_base.get(i,model_from_skeleton*skeleton.get_bone_global_pose(i))
func _apply_recovery(delta):
	if transition_from.is_empty():return
	recovery_clock+=delta
	var blend=smoothstep(0,recovery_duration,recovery_clock)
	var model_from_skeleton=global_transform.affine_inverse()*skeleton.global_transform
	var skeleton_from_model=model_from_skeleton.affine_inverse();var targets={}
	for i in transition_from:targets[i]=transition_from[i].interpolate_with(model_from_skeleton*skeleton.get_bone_global_pose(i),blend)
	for i in targets:skeleton.set_bone_global_pose_override(i,skeleton_from_model*targets[i],1,true)
	if recovery_clock>=recovery_duration:transition_from.clear()

func _calibrate_soles():
	var sole_y=INF
	for mesh in rig.find_children("*shoes*","MeshInstance3D",true,false):
		var model=global_transform.affine_inverse()*mesh.global_transform
		for p in mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:sole_y=minf(sole_y,(model*p).y)
	if sole_y==INF:return
	for side in ["l","r"]:
		var ankle=to_local(skeleton.to_global(skeleton.get_bone_global_rest(skeleton.find_bone("foot_"+side)).origin))
		sole_offsets[side]=clampf(ankle.y-sole_y,.04,.14)
func sole_offset(side:String)->float:return sole_offsets.get(side,.086)
