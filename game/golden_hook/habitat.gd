extends Node3D
## Real plant meshes, clustered by moisture, trampling and seed-head islands.
## Each spatial cell has near and middle LODs; far meadow stays instanced.
var world
var far_grass:MultiMeshInstance3D
var bins:Dictionary={}
var palettes:Dictionary={}
var rng=RandomNumberGenerator.new()
func _ready():
	rng.seed=193510
	for id in ["grass_bermuda_01","grass_medium_01","shrub_02"]:
		palettes[id]=_palette(id);palettes[id+"_lod"]=_palette(id+"_lod")
	for i in 4300:
		var p=Vector3(rng.randf_range(-41,41),0,rng.randf_range(-64,31))
		var water=minf(world._ellipse(p,world.PONDS[0],world.RADII[0]),world._ellipse(p,world.PONDS[1],world.RADII[1]))
		if water<1.02 or world.surface_at(p) in ["mud","shallow","swamp"]:continue
		if absf(p.x-sin(p.z*.09)*2)<1.2 or p.distance_to(world.CAMP)<5.0 or p.distance_to(world.LAST_CAMP)<3.5 or p.distance_to(Vector3(-17,0,-7))<1.5 or p.distance_to(Vector3(2,0,-36))<2.5:continue
		var cluster=(sin(p.x*.32+sin(p.z*.21))*sin(p.z*.29)+1)*.5
		if rng.randf()>lerpf(.16,.90,cluster):continue
		var id="grass_medium_01" if water<1.38 or cluster>.75 else "grass_bermuda_01"
		if cluster>.93 and water>1.5 and i%9==0:id="shrub_02"
		var entry={"point":world.at_ground(p),"angle":rng.randf()*TAU,"scale":rng.randf_range(.72,1.22)*(1.0 if id=="grass_bermuda_01" else .80),"index":i}
		var key=id+":"+str(floori(p.x/16))+":"+str(floori(p.z/16))
		if not bins.has(key):bins[key]={"id":id,"entries":[]}
		for tuft in (1 if id=="shrub_02" else 5):
			var point=p+Vector3(rng.randf_range(-.50,.50),0,rng.randf_range(-.50,.50))
			if minf(world._ellipse(point,world.PONDS[0],world.RADII[0]),world._ellipse(point,world.PONDS[1],world.RADII[1]))<1.025:continue
			var local_entry=entry.duplicate();local_entry.point=world.at_ground(point);local_entry.index=i*7+tuft;local_entry.angle+=tuft*1.73;bins[key].entries.append(local_entry)
	for key in bins:
		var bin=bins[key];_batch(bin.id,bin.entries,0,31);_batch(bin.id+"_lod",bin.entries,28,70)
	_far_meadow()
func _palette(id:String)->Array:
	var scene=load("res://assets/golden_hook/environment/"+id+".glb").instantiate();var meshes=[]
	for mesh in scene.find_children("*","MeshInstance3D",true,false):
		var t=mesh.transform;var parent=mesh.get_parent()
		while parent!=scene and parent is Node3D:t=parent.transform*t;parent=parent.get_parent()
		var baked=ArrayMesh.new()
		for surface in mesh.mesh.get_surface_count():
			var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.append_from(mesh.mesh,surface,Transform3D(t.basis,Vector3.ZERO));st.commit(baked)
			var source=mesh.get_active_material(surface);var material=ShaderMaterial.new();material.shader=load("res://game/golden_hook/foliage.gdshader")
			var base_id=id.trim_suffix("_lod");material.set_shader_parameter("alpha_tex",load("res://assets/golden_hook/environment/pbr/"+base_id+"_alpha.png"))
			if source is StandardMaterial3D:
				material.set_shader_parameter("diffuse_tex",source.albedo_texture)
				material.set_shader_parameter("normal_tex",source.normal_texture)
			baked.surface_set_material(surface,material)
		meshes.append({"mesh":baked,"name":str(mesh.name)})
	scene.free();return meshes
func _batch(id:String,entries:Array,near:float,far:float):
	var list=palettes[id]
	for variant in list.size():
		var transforms=[];var model=list[variant];var box=model.mesh.get_aabb()
		var target=.17 if "bermuda" in id else (.65 if "shrub" in id else (.80 if "tall" in model.name else (.48 if "large" in model.name or "mid" in model.name else .24)))
		var fit=minf(4.0,target/maxf(box.size.y,.015))
		for e in entries:
			if e.index%list.size()!=variant:continue
			var plant_basis=Basis(Vector3.UP,e.angle).scaled(Vector3.ONE*e.scale*fit)
			transforms.append(Transform3D(plant_basis,e.point-plant_basis*Vector3(box.get_center().x,box.position.y,box.get_center().z)))
		if transforms.is_empty():continue
		var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=model.mesh;mm.instance_count=transforms.size()
		for i in transforms.size():mm.set_instance_transform(i,transforms[i])
		var n=MultiMeshInstance3D.new();n.multimesh=mm;add_child(n);n.visibility_range_begin=near;n.visibility_range_end=far;n.visibility_range_begin_margin=2;n.visibility_range_end_margin=3;n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func _far_meadow():
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for a in [0.0,PI*.66,PI*1.33]:
		var r=Vector3(cos(a)*.025,0,sin(a)*.025);var tip=Vector3(sin(a)*.08,.28,cos(a)*.08)
		for v in [-r,r,tip]:st.set_uv(Vector2(.5,clampf(v.y/.28,0,1)));st.add_vertex(v)
	st.generate_normals();var mesh=st.commit();var transforms=[]
	for i in 11000:
		var p=Vector3(rng.randf_range(-44,44),0,rng.randf_range(-67,34))
		if world.surface_at(p)!="grass" or absf(p.x-sin(p.z*.09)*2)<1.1 or p.distance_to(world.CAMP)<5.2:continue
		if minf(world._ellipse(p,world.PONDS[0],world.RADII[0]),world._ellipse(p,world.PONDS[1],world.RADII[1]))<1.1:continue
		transforms.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(.5,1.2)),world.at_ground(p)))
	var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh;mm.instance_count=transforms.size()
	for i in transforms.size():mm.set_instance_transform(i,transforms[i])
	far_grass=MultiMeshInstance3D.new();far_grass.multimesh=mm;add_child(far_grass);far_grass.visibility_range_begin=35;far_grass.visibility_range_end=160
	var material=ShaderMaterial.new();material.shader=load("res://game/golden_hook/grass.gdshader");far_grass.material_override=material;far_grass.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
