extends "res://game/bridge_world.gd"

const BRIDGE_SPAN = 78.0
var bridge_span := BRIDGE_SPAN
var chain_count := 13
var environment: Environment
var sun: DirectionalLight3D
var stone: StandardMaterial3D
var earth: StandardMaterial3D
var chain_material: StandardMaterial3D
var rock_meshes: Array[MeshInstance3D] = []
var pine_scene: PackedScene
var wind_time := 0.0
var support: Node3D
var support_rope: Node3D
var modern_deck: Node3D
var modern_mode := false
var terrain_noise=FastNoiseLite.new()
var terrain_material: ShaderMaterial

func material(color: Color,metallic := 0.0) -> StandardMaterial3D:
	var mat=StandardMaterial3D.new()
	mat.albedo_color=color
	mat.roughness=.85
	mat.metallic=metallic
	return mat

func _build_material():
	terrain_noise.seed=1935
	terrain_noise.frequency=.018
	terrain_noise.fractal_octaves=5
	super._build_material()
	wood.shader=load("res://game/remaster/wood.gdshader")
	wood.set_shader_parameter("diffuse_map",load("res://assets/remaster/pbr/wood_diff.jpg"))
	wood.set_shader_parameter("normal_map",load("res://assets/remaster/pbr/wood_normal.jpg"))
	wood.set_shader_parameter("rough_map",load("res://assets/remaster/pbr/wood_rough.jpg"))
	stone=material(Color("c5c2b3"))
	stone.albedo_texture=load("res://assets/remaster/pbr/stone_diff.jpg")
	stone.normal_enabled=true
	stone.normal_texture=load("res://assets/remaster/pbr/stone_normal.jpg")
	stone.roughness_texture=load("res://assets/remaster/pbr/stone_rough.jpg")
	stone.uv1_triplanar=true
	stone.uv1_scale=Vector3(.27,.27,.27)
	earth=material(Color("c2bb9e"))
	earth.albedo_texture=load("res://assets/remaster/pbr/ground_diff.jpg")
	earth.normal_enabled=true
	earth.normal_texture=load("res://assets/remaster/pbr/ground_normal.jpg")
	earth.roughness_texture=load("res://assets/remaster/pbr/ground_rough.jpg")
	earth.uv1_triplanar=true
	earth.uv1_scale=Vector3(.2,.2,.2)
	terrain_material=ShaderMaterial.new()
	terrain_material.shader=load("res://game/remaster/terrain.gdshader")
	terrain_material.set_shader_parameter("ground_map",earth.albedo_texture)
	terrain_material.set_shader_parameter("stone_map",stone.albedo_texture)
	terrain_material.set_shader_parameter("rock_normal",stone.normal_texture)
	terrain_material.set_shader_parameter("ground_normal",earth.normal_texture)
	terrain_material.set_shader_parameter("rock_rough",stone.roughness_texture)
	chain_material=material(Color("434b4a"),.78)
	chain_material.roughness=.46
	var source=load("res://assets/remaster/environment/rocks/rock_moss_set_01.gltf").instantiate()
	for mesh in source.find_children("*","MeshInstance3D",true,false): rock_meshes.append(mesh.duplicate())
	source.free()
	pine_scene=load("res://assets/remaster/environment/pine_game.glb")

func _environment():
	var world_environment=WorldEnvironment.new()
	environment=Environment.new()
	var sky=Sky.new()
	var sky_mat=ProceduralSkyMaterial.new()
	sky_mat.sky_top_color=Color("527f9a")
	sky_mat.sky_horizon_color=Color("d7d1b7")
	sky_mat.ground_bottom_color=Color("3d504d")
	sky_mat.ground_horizon_color=Color("a8b8b5")
	sky_mat.sun_angle_max=2.5
	sky.sky_material=sky_mat
	environment.background_mode=Environment.BG_SKY
	environment.sky=sky
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy=.45
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure=1.0
	environment.fog_enabled=true
	environment.fog_light_color=Color("a9bec2")
	environment.fog_density=.0017
	environment.fog_sky_affect=.45
	if RenderingServer.get_current_rendering_method()=="forward_plus":
		environment.ssao_enabled=true
		environment.ssao_radius=1.4
		environment.ssao_intensity=1.25
		environment.ssil_enabled=true
		environment.ssil_intensity=.6
		environment.volumetric_fog_enabled=true
		environment.volumetric_fog_density=.0018
		environment.volumetric_fog_albedo=Color("9aadb2")
	world_environment.environment=environment
	add_child(world_environment)
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-34,-135,0)
	sun.light_color=Color("ffe5bf")
	sun.light_energy=1.15
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=150
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.shadow_bias=.035
	add_child(sun)

func _build_riverbanks():
	# Continuous heightfields replace the old sphere mountains. The central paths
	# are level; the outer banks descend into the gorge and rise into ridges.
	_terrain(true)
	_terrain(false)

func _canyon():
	_build_riverbanks()
	for i in 70:
		var near_bank=i%2==0
		var x=rng.randf_range(-110,110)
		var z=rng.randf_range(-6,20) if near_bank else rng.randf_range(-100,-72)
		if absf(x)<7 and (z>-2 or z<-76): continue
		rock(Vector3(x,_ground_height(x,z,near_bank)-.25,z),Vector3.ONE*rng.randf_range(1.3,4.8),Color.WHITE)
	for i in 38:
		var near_bank=i%2==0
		var x=rng.randf_range(-60,60)
		var z=rng.randf_range(6,75) if near_bank else rng.randf_range(-145,-86)
		if absf(x)<5: x+=8
		_tree(Vector3(x,_ground_height(x,z,near_bank),z),rng.randf_range(.7,1.7))
	var river=MeshInstance3D.new()
	var plane=PlaneMesh.new()
	plane.size=Vector2(500,77)
	plane.subdivide_width=180
	plane.subdivide_depth=75
	river.mesh=plane
	var river_mat=ShaderMaterial.new()
	river_mat.shader=load("res://game/remaster/river.gdshader")
	river.material_override=river_mat
	river.position=Vector3(0,-15,-39)
	add_child(river)
	# Foamy streaks near actual bank rocks are meshes within the same 3D scene.
	for i in 24:
		var foam=MeshInstance3D.new()
		var patch=PlaneMesh.new()
		patch.size=Vector2(rng.randf_range(2,6),rng.randf_range(.2,.7))
		foam.mesh=patch
		foam.position=Vector3(rng.randf_range(-100,100),-14.75,rng.randf_range(-73,-6))
		var mat=material(Color(.77,.86,.82,.35))
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		foam.material_override=mat
		foam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(foam)

func _ground_height(x: float,z: float,near_bank: bool) -> float:
	var distance=z if near_bank else -78-z
	if distance<0: return maxf(-16,distance*1.5)-.08
	var ridge=maxf(distance-13,0)*.51
	var ridges=(sin(x*.052+distance*.018)*.5+.6)*ridge
	var detail=(sin(x*.17+distance*.12)*sin(distance*.23)+sin(x*.31-distance*.1))*.7
	var value=ridges+detail*clampf((distance-8)/8,0,1)+terrain_noise.get_noise_2d(x,z)*ridge*.65
	# The authored mountain approach and village have real collision and a clear route.
	if distance<48: value*=smoothstep(5,13,absf(x))
	return value-.08

func _terrain(near_bank: bool):
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(0)
	var nx=240
	var nz=152
	var zbase=-12.0 if near_bank else -240.0
	var extent=190.0 if near_bank else 174.0
	for iz in nz:
		for ix in nx:
			var vertices: Array[Vector3]=[]
			for offset in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)]:
				var x=-230+(ix+offset.x)*460/nx
				var z=zbase+(iz+offset.y)*extent/nz
				vertices.append(Vector3(x,_ground_height(x,z,near_bank),z))
			for index in [0,1,2,1,3,2]:
				var p=vertices[index]
				surface.set_uv(Vector2(p.x,p.z)*.15)
				surface.add_vertex(p)
	surface.index()
	surface.generate_normals()
	surface.generate_tangents()
	var instance=MeshInstance3D.new()
	instance.mesh=surface.commit()
	instance.material_override=terrain_material
	add_child(instance)
	instance.create_trimesh_collision()

func rock(pos: Vector3,size_value: Vector3,_color: Color):
	if rock_meshes.is_empty(): return
	var instance=rock_meshes[rng.randi_range(0,rock_meshes.size()-1)].duplicate()
	instance.transform=Transform3D.IDENTITY
	add_child(instance)
	instance.position=pos
	instance.scale=size_value
	instance.rotation.y=rng.randf()*TAU
	instance.visibility_range_end=190
	var bounds=instance.global_transform*instance.get_aabb()
	var body=StaticBody3D.new(); body.collision_layer=32; body.collision_mask=0; add_child(body); body.position=bounds.get_center()
	var collider=CollisionShape3D.new(); collider.shape=BoxShape3D.new(); collider.shape.size=bounds.size; body.add_child(collider)

func _tree(pos: Vector3,scale_factor: float):
	if not pine_scene: return
	var tree=pine_scene.instantiate()
	add_child(tree)
	tree.position=pos
	tree.scale=Vector3.ONE*scale_factor
	tree.rotation.y=rng.randf()*TAU
	for mesh in tree.find_children("*","MeshInstance3D",true,false):
		mesh.visibility_range_end=140
		mesh.visibility_range_end_margin=12

func _bridge():
	for i in 160:
		var z=-i*.49
		if (z < -8.35 and z > -10.65) or (z < -54.8 and z > -61.95): continue
		var plank=box(Vector3(3.45,.14,.46),Vector3(0,-.09,z),wood)
		plank.rotation.y=rng.randf_range(-.012,.012)
		for x in [-1.52,1.52]: box(Vector3(.045,.008,.09),Vector3(x,-.012,z),chain_material,false)
	var link=TorusMesh.new()
	link.inner_radius=.062
	link.outer_radius=.085
	link.rings=20
	link.ring_segments=8
	var multi=MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.mesh=link
	var count=404
	multi.instance_count=13*count
	for c in 13:
		var x=-1.6+c*.4 if c<9 else (-1.86 if c<11 else 1.86)
		var y=-.16 if c<9 else (.78 if c%2==1 else 1.48)
		for i in count:
			var basis=Basis(Vector3.RIGHT,PI/2 if i%2==0 else 0.0).scaled(Vector3(.58,1,1.75))
			multi.set_instance_transform(c*count+i,Transform3D(basis,Vector3(x,y-sin(float(i)/(count-1)*PI)*.12,-i*.194)))
	var chains=MultiMeshInstance3D.new()
	chains.multimesh=multi
	chains.material_override=chain_material
	add_child(chains)
	for z in [0.0,-78.0]:
		for x in [-2.25,2.25]:
			box(Vector3(.8,2.5,1.4),Vector3(x,1.1,z),stone)
			box(Vector3(1.1,.27,1.65),Vector3(x,2.43,z),stone)
			for h in [0.0,.55,1.1,1.65]: box(Vector3(.85,.035,1.44),Vector3(x,h,z),material(Color("4c514b")),false)
		box(Vector3(5.3,.35,.65),Vector3(0,2.35,z),wood,true)
		_roof(Vector3(0,2.55,z),Vector3(6.3,1.05,2.4))
	for x in [-1.85,1.85]:
		var rail=StaticBody3D.new()
		rail.collision_layer=16
		add_child(rail)
		var collider=CollisionShape3D.new()
		var shape=BoxShape3D.new()
		shape.size=Vector3(.08,1,78)
		collider.shape=shape
		rail.add_child(collider)
		rail.position=Vector3(x,.5,-39)
		var camera_rail=StaticBody3D.new(); camera_rail.collision_layer=32; camera_rail.collision_mask=0; add_child(camera_rail)
		camera_rail.position=Vector3(x,.9,-39)
		var camera_collider=CollisionShape3D.new(); camera_collider.shape=BoxShape3D.new(); camera_collider.shape.size=Vector3(.16,2.0,78); camera_rail.add_child(camera_collider)

func _cover():
	for pos in [Vector3(-2,.45,1.5),Vector3(2.1,.45,.7),Vector3(-2.7,.45,-80.5),Vector3(2.7,.45,-80.5)]:
		box(Vector3(1.7,.80,.8),pos,stone)
		for i in 9:
			var sack=MeshInstance3D.new()
			var capsule=CapsuleMesh.new()
			capsule.radius=.145
			capsule.height=.65
			capsule.radial_segments=12
			capsule.rings=5
			sack.mesh=capsule
			sack.position=pos+Vector3((i%3-1)*.56,(i/3)*.22-.22,.03)
			sack.rotation.z=PI/2
			sack.scale.z=2.2
			sack.material_override=material(Color("7d7964").lightened(rng.randf()*.08))
			add_child(sack)
	box(Vector3(.8,.7,1.0),Vector3(-4.2,.35,3.3),wood)
	for i in 5: box(Vector3(.9,.1,2.6),Vector3(4.5,.12+i*.1,3.3),wood,false)
	support=Node3D.new()
	add_child(support)
	support.position=Vector3(2.8,.75,3)
	var brace=box(Vector3(1.2,.1,.12),support.position,wood,false)
	brace.reparent(support,true)
	for x in [-.45,.45]:
		box(Vector3(.075,.7,.075),Vector3(2.8+x,.35,3),wood,false)
	support_rope=Node3D.new()
	support.add_child(support_rope)
	for i in 5:
		var wrap=MeshInstance3D.new()
		var ring=TorusMesh.new()
		ring.inner_radius=.071
		ring.outer_radius=.082
		ring.rings=16
		ring.ring_segments=6
		wrap.mesh=ring
		wrap.material_override=material(Color("948362"))
		wrap.rotation.z=PI/2
		wrap.position.x=(i-2)*.025
		support_rope.add_child(wrap)
	support_rope.hide()

func _props():
	_flag(Vector3(-4.8,0,10.5))
	_flag(Vector3(5,0,-85))
	for pos in [Vector3(-9,0,17),Vector3(11,0,9),Vector3(-9,0,-87),Vector3(10,0,-93)]: _house(pos)
	# Route props: field stores, a map table, milestone and discarded boards.
	box(Vector3(1.2,.65,.8),Vector3(-2,.28,28),wood)
	box(Vector3(1.1,.06,.7),Vector3(-3,.85,5.5),wood)
	for x in [-3.4,-2.6]: box(Vector3(.07,.85,.07),Vector3(x,.42,5.5),wood,false)
	var map_page=box(Vector3(.85,.01,.5),Vector3(-3,.89,5.5),material(Color("d6c6a1")),false)
	map_page.rotation.y=.18
	for i in 14:
		var z=rng.randf_range(-77,-18)
		if z<-54 and z>-62: continue
		var scrap=box(Vector3(rng.randf_range(.3,.7),.08,rng.randf_range(.35,1.2)),Vector3(rng.randf_range(-1.4,1.4),.01,z),wood,false)
		scrap.rotation.y=rng.randf_range(-.7,.7)
	for z in [-14.0,-46.0,-70.0]:
		var cloth=box(Vector3(.18,.6,.01),Vector3(-1.85,.9,z),material(Color("8a3f2d")),false)
		cloth.rotation.z=.06

func _house(pos: Vector3):
	box(Vector3(5.2,3.1,4.0),pos+Vector3(0,1.5,0),material(Color("a1937b")))
	for x in [-1.5,1.5]:
		box(Vector3(.85,1,.10),pos+Vector3(x,1.8,2.06),wood,false)
		for j in 4: box(Vector3(.035,1.05,.03),pos+Vector3(x-.3+j*.2,1.8,2.13),chain_material,false)
	box(Vector3(.9,1.95,.10),pos+Vector3(0,.94,2.07),wood,false)
	_roof(pos+Vector3(0,3.05,0),Vector3(6.4,1.45,5.4))
	for x in [-2.75,2.75]: box(Vector3(.15,3.1,.15),pos+Vector3(x,1.5,2.45),wood)

func _roof(pos: Vector3,size_value: Vector3):
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(0)
	var segments=12
	for side in [-1,1]:
		for i in segments:
			var a=float(i)/segments
			var b=float(i+1)/segments
			var p0=Vector3(-size_value.x/2,size_value.y*pow(1-a,1.7),side*a*size_value.z/2)
			var p1=Vector3(size_value.x/2,p0.y,p0.z)
			var p2=Vector3(-size_value.x/2,size_value.y*pow(1-b,1.7),side*b*size_value.z/2)
			var p3=Vector3(size_value.x/2,p2.y,p2.z)
			for p in [p0,p1,p2,p1,p3,p2]:
				surface.set_uv(Vector2(p.x,p.z))
				surface.add_vertex(p)
	surface.index(); surface.generate_normals(); surface.generate_tangents()
	var roof=MeshInstance3D.new(); roof.add_to_group("detail_roof")
	roof.mesh=surface.commit()
	var tile=material(Color("414a48"))
	tile.cull_mode=BaseMaterial3D.CULL_DISABLED
	roof.material_override=tile
	roof.position=pos
	add_child(roof)
	# A conservative volume also protects the camera from the decorative tile ribs.
	var obstruction=StaticBody3D.new(); obstruction.collision_layer=1; obstruction.collision_mask=0
	var shape_node=CollisionShape3D.new(); var roof_shape=BoxShape3D.new()
	roof_shape.size=size_value; shape_node.shape=roof_shape
	add_child(obstruction); obstruction.position=pos+Vector3(0,size_value.y*.5,0); obstruction.add_child(shape_node)
	# Repeated thin ribs give the tiled roof a readable silhouette at both gates.
	for i in int(size_value.x/.18):
		for side in [-1,1]:
			var rib=box(Vector3(.045,.055,size_value.z*.52),pos+Vector3(-size_value.x/2+i*.18,size_value.y*.38,side*size_value.z*.26),tile,false)
			rib.add_to_group("legacy_roof_rib")
			rib.rotation.x=side*.28

func set_quality(high: bool):
	if mission and mission.get("vegetation"):mission.vegetation.set_quality(high)
	if RenderingServer.get_current_rendering_method()=="forward_plus":
		environment.ssao_enabled=high
		environment.ssil_enabled=high
		environment.volumetric_fog_enabled=high
	sun.directional_shadow_max_distance=150 if high else 75
	get_viewport().scaling_3d_scale=1.0 if high else .75
	get_viewport().msaa_3d=Viewport.MSAA_4X if high else Viewport.MSAA_DISABLED

func set_modern():
	modern_mode=true
	modern_deck=Node3D.new()
	add_child(modern_deck)
	for i in 160:
		var plank=box(Vector3(3.45,.12,.46),Vector3(0,-.01,-i*.49),wood,false)
		plank.reparent(modern_deck,true)
	sun.light_color=Color("fff2d9")
	sun.light_energy=1.35
	environment.fog_density=.001

func _process(delta):
	wind_time+=delta
	if support and mission.stage=="brace" and not mission.tasks.get("brace",false): support.rotation.z=sin(wind_time*1.8)*.09

func _exit_tree():
	for prototype in rock_meshes: prototype.free()
	rock_meshes.clear()
