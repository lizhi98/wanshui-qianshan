extends Node3D

var rig: Node3D
var skeleton: Skeleton3D
var animator: AnimationPlayer
var carry_anchor: Node3D
var rifle: Node3D
var muzzle: Node3D
var head_props: Node3D
var pack: Node3D
var mode := "idle"
var speed := 0.0
var action_time := 0.0
var hurt_time := 0.0
var uniform := Color("596e72")
var current_clip := ""
var dead := false
var hand_error := 0.0
var hand_targets: Array = []
var last_mode := ""
var pose_time := 0.0

func _ready():
	rig = load("res://assets/characters/Soldier.gltf").instantiate()
	add_child(rig)
	skeleton = rig.find_child("*", true, false) as Skeleton3D
	for child in rig.find_children("*", "Skeleton3D", true, false):
		skeleton = child
	animator = rig.find_children("*", "AnimationPlayer", true, false)[0]
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	# Godot strips its recognized _Loop import suffix. Expose the original clip names too.
	var library = animator.get_animation_library("")
	for clip in ["Idle", "Walk", "Sprint", "Jump", "Crouch_Fwd", "Pistol_Idle"]:
		if library.has_animation(clip):
			var animation_clip = library.get_animation(clip)
			animation_clip.loop_mode = Animation.LOOP_LINEAR
			library.add_animation(clip+"_Loop", animation_clip)
	for clip in animator.get_animation_list():
		if "Loop" in clip:
			animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_apply_uniform()
	carry_anchor = Node3D.new()
	carry_anchor.name = "CarryAnchor"
	add_child(carry_anchor)
	carry_anchor.position = Vector3(0, 1.16, 1.48)
	_create_equipment()
	play("Idle_Loop")

func _apply_uniform():
	var shader = Shader.new()
	shader.code = """shader_type spatial;
uniform vec4 cloth : source_color;
varying vec3 rest_pos;
void vertex(){ rest_pos = VERTEX; }
void fragment(){
 vec3 c = cloth.rgb;
 if(rest_pos.y > 1.57 || (abs(rest_pos.x)>0.74 && rest_pos.y>0.8)) c=vec3(0.59,0.40,0.27);
 if(rest_pos.y < 0.19) c=vec3(0.12,0.105,0.085);
 if(rest_pos.y > 0.91 && rest_pos.y < 0.98 && abs(rest_pos.x)<0.24) c=vec3(0.18,0.14,0.105);
 ALBEDO=c; ROUGHNESS=0.91;
}"""
	for mesh in rig.find_children("*", "MeshInstance3D", true, false):
		if "Super" in mesh.name:
			var mat = ShaderMaterial.new()
			mat.shader = shader
			mat.set_shader_parameter("cloth", uniform)
			mesh.material_override = mat

func material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color.srgb_to_linear()
	mat.roughness = 0.86
	return mat

func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material(color)
	parent.add_child(node)
	node.position = pos
	return node

func _create_equipment():
	head_props = Node3D.new()
	add_child(head_props)
	var hat = MeshInstance3D.new()
	var hat_mesh = CylinderMesh.new()
	hat_mesh.top_radius = 0.108
	hat_mesh.bottom_radius = 0.128
	hat_mesh.height = 0.095
	hat_mesh.radial_segments = 12
	hat.mesh = hat_mesh
	hat.material_override = material(uniform.darkened(0.15))
	head_props.add_child(hat)
	hat.position = Vector3(0, 0.20, 0)
	box(head_props, Vector3(0.20, 0.025, 0.13), Vector3(0, 0.158, 0.10), uniform.darkened(0.2))
	# Small five-point insignia created as a planar mesh.
	var star = ImmediateMesh.new()
	star.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 10:
		var a = float(i)*TAU/10.0
		var b = float(i+1)*TAU/10.0
		var r1 = 0.022 if i%2 == 0 else 0.009
		var r2 = 0.022 if (i+1)%2 == 0 else 0.009
		star.surface_add_vertex(Vector3(0, 0.183, 0.128))
		star.surface_add_vertex(Vector3(sin(a)*r1, 0.183+cos(a)*r1, 0.129))
		star.surface_add_vertex(Vector3(sin(b)*r2, 0.183+cos(b)*r2, 0.129))
	star.surface_end()
	var emblem = MeshInstance3D.new()
	emblem.mesh = star
	var emblem_mat = material(Color("b34235") if uniform.b > uniform.r else Color("bdad7c"))
	emblem_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	emblem.material_override = emblem_mat
	head_props.add_child(emblem)
	pack = Node3D.new()
	add_child(pack)
	box(pack, Vector3(0.32, 0.40, 0.14), Vector3(0, 0, -0.18), Color("655f42"))
	box(pack, Vector3(0.36, 0.09, 0.15), Vector3(0, 0.22, -0.18), Color("81745b"))
	rifle = Node3D.new()
	add_child(rifle)
	box(rifle, Vector3(0.065, 0.075, 0.72), Vector3(0, 0, 0.08), Color("5d3e28"))
	box(rifle, Vector3(0.038, 0.045, 0.92), Vector3(0, 0.035, 0.24), Color("30373a"))
	box(rifle, Vector3(0.05, 0.13, 0.08), Vector3(0, -0.07, -0.04), Color("272d2d"))
	muzzle = Node3D.new()
	rifle.add_child(muzzle)
	muzzle.position = Vector3(0, 0.035, 0.70)

func play(clip: String, blend := 0.18):
	if current_clip == clip:
		return
	if animator.has_animation(clip):
		current_clip = clip
		animator.play(clip, blend)

func hurt():
	hurt_time = 0.35
	play("Hit_Chest", 0.06)

func _process(delta):
	if not skeleton:
		return
	action_time += delta
	if last_mode != mode:
		pose_time = 0
		last_mode = mode
	pose_time += delta
	hurt_time = maxf(0.0, hurt_time-delta)
	var clip = "Idle_Loop"
	match mode:
		"walk", "carry": clip = "Walk_Loop" if speed > 0.1 else "Idle_Loop"
		"run": clip = "Sprint_Loop"
		"aim": clip = "Pistol_Idle_Loop"
		"jump": clip = "Jump_Loop"
		"pickup": clip = "Fixing_Kneeling"
		"place": clip = "Fixing_Kneeling"
		"climb": clip = "Walk_Loop"
		"reload": clip = "Pistol_Reload"
		"dead": clip = "Death01"
	if hurt_time <= 0:
		play(clip)
	animator.speed_scale = clampf(speed/2.2, 0.6, 1.35) if clip == "Walk_Loop" else 1.0
	skeleton.clear_bones_global_pose_override()
	animator.advance(delta)
	if mode in ["pickup","place"]:
		animator.seek(minf(pose_time*2.4,1.8),true)
		_bend_torso(1.2)
	_update_accessory(head_props, "Head")
	_update_accessory(pack, "spine_03")
	rifle.visible = mode not in ["carry", "pickup", "place", "climb", "dead"]
	if rifle.visible:
		rifle.position = Vector3(-0.08, 1.37 if mode == "aim" else 1.25, 0.18)
		rifle.rotation = Vector3(-0.03 if mode == "aim" else -0.37, -0.04, 0.0)
		_solve_arm("r", rifle.position + Vector3(0, -0.015, -0.11))
		_solve_arm("l", rifle.position + Vector3(0.04, 0.02, 0.18))
	elif mode == "carry":
		carry_anchor.position.y = 1.16+sin(action_time*5.0)*0.014
		_solve_arm("r", Vector3(-0.39, carry_anchor.position.y, 0.29))
		_solve_arm("l", Vector3(0.39, carry_anchor.position.y, 0.29))
	elif mode == "climb":
		_solve_arm("r", Vector3(-0.23, 1.36, 0.38))
		_solve_arm("l", Vector3(0.23, 1.36, 0.38))
	if hand_targets.size() == 2:
		_solve_arm("r", to_local(hand_targets[0]))
		_solve_arm("l", to_local(hand_targets[1]))

func _update_accessory(node: Node3D, bone_name: String):
	var index = skeleton.find_bone(bone_name)
	var pose = skeleton.get_bone_global_pose(index)
	var rest = skeleton.get_bone_global_rest(index)
	node.global_transform = skeleton.global_transform * Transform3D(pose.basis * rest.basis.inverse(), pose.origin)

func _bend_torso(angle: float):
	var index = skeleton.find_bone("spine_01")
	var parent = skeleton.get_bone_parent(index)
	var pose = skeleton.get_bone_global_pose(index)
	var parent_basis = skeleton.get_bone_global_pose(parent).basis
	var local_basis = parent_basis.inverse()*Basis(Vector3.RIGHT,angle)*pose.basis
	skeleton.set_bone_pose_rotation(index,local_basis.orthonormalized().get_rotation_quaternion())
	skeleton.force_update_all_bone_transforms()

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
	skeleton.set_bone_global_pose_override(upper, a, 1.0, true)
	skeleton.set_bone_global_pose_override(lower, b, 1.0, true)
	skeleton.set_bone_global_pose_override(hand, c, 1.0, true)
	hand_error = maxf(hand_error, wrist.distance_to(goal))

func reset_pose():
	mode = "idle"
	dead = false
	hurt_time = 0.0
	hand_targets = []
	current_clip = ""
	play("Idle_Loop", 0.0)
