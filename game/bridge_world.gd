extends Node3D

var board: MeshInstance3D
var repair_body: StaticBody3D
var repair_shape: CollisionShape3D
var repair_enabled := false
var mission
var rng = RandomNumberGenerator.new()
var wood: ShaderMaterial
var board_start := Vector3(0.95, 0.15, 2.0)
var board_final := Vector3(0, -0.085, -9.5)
var smoke: Array[CPUParticles3D] = []

func _ready():
	rng.seed = 19350529
	_build_material()
	_environment()
	_canyon()
	_bridge()
	_cover()
	_board()
	_props()

func material(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color.srgb_to_linear()
	mat.roughness = 0.84
	mat.metallic = metallic
	return mat

func _build_material():
	var shader = Shader.new()
	shader.code = """shader_type spatial;
varying vec3 p;
void vertex(){p=VERTEX;}
void fragment(){
 float grain=sin(p.z*35.0+sin(p.x*9.0)*1.4)*0.03+sin(p.z*128.0+p.x*9.0)*0.016;
 ALBEDO=vec3(0.29,0.20,0.12)+grain;
 ROUGHNESS=0.94;
}"""
	wood = ShaderMaterial.new()
	wood.shader = shader

func box(size: Vector3, pos: Vector3, mat: Material, solid := true) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	add_child(instance)
	instance.position = pos
	if solid:
		var body = StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		body.position = pos
		var collider = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		body.add_child(collider)
	return instance

func _environment():
	var world_environment = WorldEnvironment.new()
	var env = Environment.new()
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("49666c")
	sky_material.sky_horizon_color = Color("b9b9a0")
	sky_material.ground_bottom_color = Color("303d3a")
	sky_material.ground_horizon_color = Color("b1b19a")
	sky_material.sun_angle_max = 8.0
	sky_material.sun_curve = 0.06
	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a3b7b6")
	env.ambient_light_energy = 0.32
	env.ambient_light_sky_contribution = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("8b9b92")
	env.fog_density = 0.0034
	env.fog_sky_affect = 0.24
	world_environment.environment = env
	add_child(world_environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-43, -32, 0)
	sun.light_color = Color("ffe5b7")
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 85
	sun.shadow_bias = 0.04
	add_child(sun)

func rock(pos: Vector3, size: Vector3, color: Color):
	var mesh = SphereMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 4
	mesh.radius = 1
	mesh.height = 2
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	node.position = pos
	node.scale = size
	node.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf()*TAU, rng.randf_range(-0.25, 0.25))
	add_child(node)

func _canyon():
	box(Vector3(24, 1, 12), Vector3(0,-0.52,6), material(Color("51564a")))
	box(Vector3(25, 1, 14), Vector3(0,-0.52,-32.6), material(Color("656656")))
	for shore in [1, -1]:
		for i in 21:
			var x = (i-10)*5.6
			var z = 3 if shore == 1 else -30
			rock(Vector3(x,-6.5,z), Vector3(4.6+rng.randf()*2,6.2,3.5+rng.randf()*2), Color("4c5550").lightened(rng.randf()*0.14))
		for i in 12:
			var x = (i-5)*12.5
			var z = rng.randf_range(30,48) if shore == 1 else rng.randf_range(-65,-47)
			rock(Vector3(x,2,z), Vector3(12+rng.randf()*8,15+rng.randf()*15,10+rng.randf()*8), Color("43574f").lightened(rng.randf()*0.06))
	var river = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(220,48)
	plane.subdivide_width = 180
	plane.subdivide_depth = 90
	river.mesh = plane
	var river_mat = ShaderMaterial.new()
	river_mat.shader = load("res://game/river.gdshader")
	river.material_override = river_mat
	river.position = Vector3(0,-11,-13)
	add_child(river)
	for i in 40:
		var side = 1 if i%2 == 0 else -1
		var x = rng.randf_range(-22,22)
		if absf(x)<7: x = (7+rng.randf()*10)*(-1 if x<0 else 1)
		_tree(Vector3(x,0, rng.randf_range(2,14) if side==1 else rng.randf_range(-40,-29)), rng.randf_range(0.75,1.8))

func _tree(pos: Vector3, scale_factor: float):
	var tree = Node3D.new()
	add_child(tree)
	tree.position = pos
	var trunk = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.07
	cylinder.bottom_radius = 0.13
	cylinder.height = 2.8
	cylinder.radial_segments = 6
	trunk.mesh = cylinder
	trunk.position.y = 1.4
	trunk.material_override = material(Color("413c2c"))
	tree.add_child(trunk)
	for i in 3:
		var foliage = MeshInstance3D.new()
		var cone = CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 1.15-i*0.23
		cone.height = 2.1
		cone.radial_segments = 7
		foliage.mesh = cone
		foliage.position.y = 2+i*0.7
		foliage.material_override = material(Color("344c39").lightened(i*0.035))
		tree.add_child(foliage)
	tree.scale = Vector3.ONE*scale_factor

func _bridge():
	for i in 53:
		var z = -i*0.49
		if (z < -8.35 and z > -10.65) or (z < -16.85 and z > -20.9):
			continue
		var plank = box(Vector3(3.45,0.14,0.46), Vector3(0,-0.09,z), wood)
		plank.rotation.y = rng.randf_range(-0.012,0.012)
		for x in [-1.52,1.52]:
			box(Vector3(0.045,0.008,0.09), Vector3(x,-0.012,z), material(Color("2b302c")),false)
	var torus = TorusMesh.new()
	torus.inner_radius = 0.062
	torus.outer_radius = 0.085
	torus.rings = 8
	torus.ring_segments = 5
	var transforms: Array[Transform3D] = []
	for c in 13:
		var x = -1.6+c*0.4 if c<9 else (-1.86 if c<11 else 1.86)
		var y = -0.16 if c<9 else (0.78 if c%2==1 else 1.48)
		for i in 135:
			var z = -i*0.194
			var link_basis = Basis(Vector3.RIGHT, PI/2 if i%2==0 else 0.0).scaled(Vector3(0.58,1,1.75))
			transforms.append(Transform3D(link_basis, Vector3(x,y-sin(float(i)/134*PI)*0.12,z)))
	var multi = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = torus
	multi.instance_count = transforms.size()
	for i in transforms.size(): multi.set_instance_transform(i,transforms[i])
	var chains = MultiMeshInstance3D.new()
	chains.multimesh = multi
	chains.material_override = material(Color("2b3433"), 0.70)
	add_child(chains)
	for z in [0, -26]:
		for x in [-2.1,2.1]:
			box(Vector3(0.38,2.5,0.50),Vector3(x,1.05,z),material(Color("69695b")))
			box(Vector3(0.66,0.3,0.8),Vector3(x,2.4,z),material(Color("494f47")))
		box(Vector3(4.9,0.32,0.50),Vector3(0,2.25,z),wood,false)
	# Physical side rails block sideways falls during normal walking, but not projectiles.
	for x in [-1.85,1.85]:
		var rail = StaticBody3D.new()
		rail.collision_layer = 16
		add_child(rail)
		var collider = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.08,1.0,26)
		collider.shape = shape
		rail.add_child(collider)
		rail.position = Vector3(x,0.5,-13)

func _cover():
	var stone = material(Color("716e57"))
	for position_value in [Vector3(-1.9,0.5,1), Vector3(1.8,0.5,0.5), Vector3(-2.7,0.5,-28.6), Vector3(2.7,0.5,-28.6)]:
		# Stacked sandbags wrap collision, leaving a shoulder-height firing opening.
		box(Vector3(1.6,0.86,0.8), position_value+Vector3(0,-0.1,0),stone)
		for row in 3:
			for col in 3:
				var sack = box(Vector3(0.62,0.24,0.88),position_value+Vector3((col-1)*0.55+(0.10 if row%2==1 else 0.0),row*0.25-0.32,0),material(Color("7b785e").lightened(rng.randf()*0.06)),false)
				sack.rotation.y = rng.randf_range(-0.07,0.07)
	box(Vector3(1.0,1.65,1.0), Vector3(-4.2,0.7,3.3),wood)

func _board():
	board = box(Vector3(0.94,0.13,2.62), board_start,wood,false)
	board.name = "RepairTimber"
	repair_body = StaticBody3D.new()
	repair_body.name = "RepairedBridgeCollision"
	repair_body.collision_layer = 0
	add_child(repair_body)
	repair_body.position = board_final
	repair_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.94,0.13,2.62)
	repair_shape.shape = shape
	repair_body.add_child(repair_shape)
	for i in 3:
		box(Vector3(0.9,0.08,2.6), board_start+Vector3(0.12*i,-0.05-i*0.05,0.18*i),wood,false)

func enable_repair():
	repair_enabled = true
	repair_body.collision_layer = 1

func reset_board():
	if board.get_parent() != self:
		board.reparent(self, false)
	board.position = board_start
	board.rotation = Vector3.ZERO
	repair_enabled = false
	repair_body.collision_layer = 0

func _props():
	_flag(Vector3(-3.5,0,5.2))
	_flag(Vector3(4.8,0,-33))
	for position_value in [Vector3(-4,0,-31),Vector3(5,0,-29)]:
		var particles = CPUParticles3D.new()
		particles.amount = 18
		particles.lifetime = 6
		particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 0.55
		particles.direction = Vector3(0,1,0)
		particles.spread = 12
		particles.gravity = Vector3(0,0.18,0)
		particles.initial_velocity_min = 0.7
		particles.initial_velocity_max = 1.0
		particles.scale_amount_min = 0.7
		particles.scale_amount_max = 1.9
		var puff = SphereMesh.new()
		puff.radius = 0.6
		puff.height = 1.2
		puff.radial_segments = 6
		puff.rings = 4
		particles.mesh = puff
		var smoke_mat = material(Color(0.25,0.27,0.24,0.13))
		smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		particles.material_override = smoke_mat
		particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(particles)
		particles.position = position_value
		smoke.append(particles)

func _flag(pos: Vector3):
	box(Vector3(0.06,3.9,0.06),pos+Vector3(0,1.9,0),material(Color("544b37")))
	var banner = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(1.45,0.9)
	plane.subdivide_width = 16
	banner.mesh = plane
	banner.rotation.x = PI/2
	banner.position = pos+Vector3(0.75,3.15,0)
	var shader = Shader.new()
	shader.code = "shader_type spatial; render_mode cull_disabled; void vertex(){VERTEX.y+=sin(VERTEX.x*5.0+TIME*3.0)*0.08;} void fragment(){ALBEDO=vec3(0.45,0.10,0.075);ROUGHNESS=0.95;}"
	var flag_material = ShaderMaterial.new()
	flag_material.shader = shader
	banner.material_override = flag_material
	add_child(banner)
