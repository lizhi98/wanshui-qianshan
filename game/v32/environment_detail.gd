extends Node3D
var mission
var meshes:Dictionary={}
func setup(m):
	mission=m
	var world=mission.world
	for mesh in world.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh is BoxMesh:
			var size_value=mesh.mesh.size
			if size_value.is_equal_approx(Vector3(5.2,3.1,4.0)):
				var wall=mission.world.stone.duplicate(); wall.albedo_color=Color(.66,.62,.54); wall.uv1_scale=Vector3.ONE*.65; mesh.material_override=wall
			if minf(size_value.x,minf(size_value.y,size_value.z))>.035:
				mesh.mesh=_bevel(size_value,minf(.035,minf(size_value.x,minf(size_value.y,size_value.z))*.12))
	var rng=RandomNumberGenerator.new(); rng.seed=32029
	for side in [0,1]:
		for i in 22:
			var x=(-1 if i%2 else 1)*(6.5+float(i/2)*4.3)
			var z=-2.2-rng.randf()*2.8 if side==0 else -75.7+rng.randf()*2.8
			var y=world._ground_height(x,z,side==0)
			world.rock(Vector3(x,y-.5,z),Vector3.ONE*rng.randf_range(1.7,3.0),Color.WHITE)
	for point in [Vector3(-9,0,17),Vector3(11,0,9),Vector3(-9,0,-87),Vector3(10,0,-93)]: _house_detail(point)
	for gun in mission.battlefield.guns: _gun_detail(gun)
	var roof_material=ShaderMaterial.new(); roof_material.shader=load("res://game/v32/roof.gdshader")
	for roof in get_tree().get_nodes_in_group("detail_roof"): roof.material_override=roof_material
	for rib in get_tree().get_nodes_in_group("legacy_roof_rib"): rib.hide()
	# V3.3 replaces the old triangular grass with curved blade and leaf meshes.
	world.environment.ssao_intensity=1.25; world.environment.ssao_radius=1.1
	world.environment.fog_density=.00115
	world.environment.volumetric_fog_density=.00125

func _bevel(size_value:Vector3,radius:float)->ArrayMesh:
	var key=str(size_value)+str(radius)
	if meshes.has(key): return meshes[key]
	var surface=SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half=size_value*.5; var inner=half-Vector3.ONE*radius
	for axis in 3:
		var u=(axis+1)%3; var v=(axis+2)%3
		for sign_value in [-1,1]:
			var us=[-half[u],-inner[u],inner[u],half[u]]; var vs=[-half[v],-inner[v],inner[v],half[v]]
			for a in 3:
				for b in 3:
					var points=[]
					for offset in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
						var p=Vector3.ZERO; p[axis]=half[axis]*sign_value; p[u]=us[a+offset.x]; p[v]=vs[b+offset.y]
						var core=p.clamp(-inner,inner); var normal=(p-core).normalized()
						points.append({"p":core+normal*radius,"n":normal,"uv":Vector2(p[u],p[v])*.55})
					var order=[0,2,1,1,2,3] if sign_value>0 else [0,1,2,1,3,2]
					for index in order:
						var point=points[index]; surface.set_normal(point.n); surface.set_uv(point.uv); surface.add_vertex(point.p)
	surface.index(); surface.generate_tangents(); var result=surface.commit(); meshes[key]=result; return result

func _box(size_value:Vector3,point:Vector3,material:Material,parent:Node=null)->MeshInstance3D:
	if parent==null: parent=self
	var mesh=MeshInstance3D.new(); mesh.mesh=_bevel(size_value,minf(.018,minf(size_value.x,minf(size_value.y,size_value.z))*.15)); mesh.material_override=material; parent.add_child(mesh); mesh.position=point; return mesh

func _house_detail(point:Vector3):
	var wood=mission.world.wood; var stone=mission.world.stone
	var plaster=StandardMaterial3D.new(); plaster.albedo_texture=load("res://assets/remaster/pbr/stone_diff.jpg"); plaster.normal_enabled=true; plaster.normal_texture=load("res://assets/remaster/pbr/stone_normal.jpg"); plaster.albedo_color=Color(.63,.59,.51); plaster.uv1_triplanar=true; plaster.uv1_scale=Vector3.ONE*.7
	for side in [-1,1]:
		var z=point.z+side*2.04
		_box(Vector3(5.35,.28,.19),Vector3(point.x,.14,z),stone)
		_box(Vector3(5.5,.12,.16),Vector3(point.x,2.90,z),wood)
		for x in [-2.47,2.47]: _box(Vector3(.13,2.78,.16),Vector3(point.x+x,1.52,z),wood)
		for x in [-1.5,1.5]:
			for offset in [-.49,.49]: _box(Vector3(.08,1.18,.14),Vector3(point.x+x+offset,1.8,z+side*.13),wood)
			for y in [1.25,2.35]: _box(Vector3(1.05,.09,.15),Vector3(point.x+x,y,z+side*.13),wood)
			for slat in 5:
				var bar=_box(Vector3(.12,1.02,.075),Vector3(point.x+x-.34+slat*.17,1.8,z+side*.08),wood)
				bar.rotation.y=.12*side
		for x in [-.52,.52]: _box(Vector3(.12,2.10,.17),Vector3(point.x+x,1.05,z+side*.10),wood)
		_box(Vector3(1.18,.15,.25),Vector3(point.x,2.10,z+side*.11),wood)
		_box(Vector3(1.45,.16,.58),Vector3(point.x,.08,z+side*.30),stone)
	for x in [-2.61,2.61]:
		for y in [.45,1.05,1.65,2.25]: _box(Vector3(.20,.26,4.05),point+Vector3(x,y,0),plaster)

func _gun_detail(gun:Dictionary):
	var root=gun.root; var wood=mission.world.wood; var iron=mission.world.chain_material
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh is BoxMesh: mesh.mesh=_bevel(mesh.mesh.size,.016)
		elif mesh.mesh is CylinderMesh:
			if mesh.mesh.bottom_radius>.5:
				var rim=TorusMesh.new(); rim.inner_radius=.45; rim.outer_radius=.55; rim.rings=32; rim.ring_segments=8; mesh.mesh=rim; mesh.material_override=wood
				for j in 8:
					var spoke=_box(Vector3(.09,.055,.94),mesh.position,wood,root); spoke.rotation.x=j*PI/8
				var tire=MeshInstance3D.new(); tire.mesh=TorusMesh.new(); tire.mesh.inner_radius=.535; tire.mesh.outer_radius=.568; tire.mesh.rings=32; tire.mesh.ring_segments=6; tire.material_override=iron; tire.position=mesh.position; tire.rotation.z=PI/2; root.add_child(tire)
			else: mesh.mesh.radial_segments=32; mesh.material_override=iron
	for z in [-.6,.85]:
		var band=MeshInstance3D.new(); band.mesh=CylinderMesh.new(); band.mesh.top_radius=.17; band.mesh.bottom_radius=.17; band.mesh.height=.09; band.mesh.radial_segments=32; band.material_override=iron; gun.barrel.add_child(band); band.position.z=z; band.rotation.x=PI/2
	var bore=MeshInstance3D.new(); bore.mesh=CylinderMesh.new(); bore.mesh.top_radius=.105; bore.mesh.bottom_radius=.105; bore.mesh.height=.014; bore.mesh.radial_segments=32; var dark=StandardMaterial3D.new(); dark.albedo_color=Color(.018,.019,.018); bore.material_override=dark; gun.barrel.add_child(bore); bore.position.z=1.38; bore.rotation.x=PI/2

func _grass():
	var surface=SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 6:
		var angle=float(i)*TAU/6; var side=Vector3(cos(angle),0,sin(angle))*.025; var center=Vector3(sin(angle)*.08,0,cos(angle)*.08)
		for p in [center-side,center+side,center+Vector3(sin(angle)*.06,.22+float(i%3)*.03,cos(angle)*.06)]:
			surface.set_color(Color(.11,.17,.055) if p.y<.1 else Color(.28,.32,.105)); surface.set_normal(Vector3.UP); surface.add_vertex(p)
	var mat=StandardMaterial3D.new(); mat.vertex_color_use_as_albedo=true; mat.cull_mode=BaseMaterial3D.CULL_DISABLED; mat.roughness=.95
	var mesh=MultiMeshInstance3D.new(); mesh.multimesh=MultiMesh.new(); mesh.multimesh.transform_format=MultiMesh.TRANSFORM_3D; mesh.multimesh.mesh=surface.commit(); mesh.multimesh.instance_count=2200; mesh.material_override=mat; mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; mesh.visibility_range_end=65; add_child(mesh)
	mesh.visibility_range_end=150
	var random=RandomNumberGenerator.new(); random.seed=321
	mesh.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	for i in 2200:
		var side=i%2==0; var x=random.randf_range(5.6,25)*(-1 if i%3 else 1); var z=random.randf_range(3,42) if side else random.randf_range(-119,-82)
		var p=Vector3(x,mission.world._ground_height(x,z,side),z); var scale_value=random.randf_range(.6,1.4)
		mesh.multimesh.set_instance_transform(i,Transform3D(Basis(Vector3.UP,random.randf()*TAU).scaled(Vector3.ONE*scale_value),p))
