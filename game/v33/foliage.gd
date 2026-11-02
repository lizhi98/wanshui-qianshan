extends Node3D
var mission
var groups:Array=[]
var rng=RandomNumberGenerator.new()
var vegetation_material:ShaderMaterial
func setup(m):
	mission=m;rng.seed=33029
	vegetation_material=ShaderMaterial.new();vegetation_material.shader=load("res://game/v33/foliage.gdshader")
	var grasses=[]
	for variant in 4:grasses.append(_grass_mesh(variant))
	for bank in [true,false]:
		for kind in 4:
			var points=[]
			for i in 1350:
				var x=rng.randf_range(5.5,38)*(-1 if i%2 else 1);var z=rng.randf_range(2.4,49) if bank else rng.randf_range(-125,-81.6)
				var patch=sin(x*.29+sin(z*.21)*1.7)*sin(z*.22-x*.09)
				if patch<-.18:continue
				points.append(_at(Vector3(x,0,z),bank,rng.randf_range(.55,1.15)))
			_instances("Curved_meadow_grass",grasses[kind],points,vegetation_material,85)
		var fern_points=[];var bush_points=[];var reed_points=[]
		for i in 160:
			var x=rng.randf_range(6,33)*(-1 if i%2 else 1);var z=rng.randf_range(4,41) if bank else rng.randf_range(-117,-83)
			fern_points.append(_at(Vector3(x,0,z),bank,rng.randf_range(.65,1.35)))
		for i in 65:
			var x=rng.randf_range(7.3,37)*(-1 if i%2 else 1);var z=rng.randf_range(5,43) if bank else rng.randf_range(-121,-84)
			bush_points.append(_at(Vector3(x,0,z),bank,rng.randf_range(.65,1.25)))
		for i in 120:
			var x=rng.randf_range(5.7,43)*(-1 if i%2 else 1);var z=rng.randf_range(-1.0,2) if bank else rng.randf_range(-81,-78.5)
			reed_points.append(_at(Vector3(x,0,z),bank,rng.randf_range(.65,1.3)))
		_instances("Fern_fronds",_fern_mesh(),fern_points,vegetation_material,90)
		_instances("Layered_leaf_shrubs",_bush_mesh(),bush_points,vegetation_material,125)
		_instances("Riverbank_sedges",_grass_mesh(4),reed_points,vegetation_material,105)
	_deadwood()
	set_quality(mission.high_quality)
func _at(p:Vector3,near:bool,scale_value:float)->Transform3D:
	p.y=mission.world._ground_height(p.x,p.z,near)-.03
	return Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_value),p)
func _instances(label:String,mesh:ArrayMesh,points:Array,material:Material,range_end:float):
	var node=MultiMeshInstance3D.new();node.name=label;add_child(node);node.multimesh=MultiMesh.new();node.multimesh.transform_format=MultiMesh.TRANSFORM_3D;node.multimesh.mesh=mesh;node.multimesh.instance_count=points.size();node.material_override=material
	var center=Vector3.ZERO
	for instance_transform in points:center+=instance_transform.origin
	center/=maxi(1,points.size());node.position=center
	node.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.visibility_range_end=range_end;node.visibility_range_end_margin=12;node.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	for i in points.size():
		var instance_transform:Transform3D=points[i];instance_transform.origin-=center;node.multimesh.set_instance_transform(i,instance_transform)
	groups.append(node)
func set_quality(high:bool):
	for node in groups:node.multimesh.visible_instance_count=node.multimesh.instance_count if high else int(node.multimesh.instance_count*.42)
func _triangle(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,color:Color):
	var normal=(b-a).cross(c-a).normalized()
	for p in [a,b,c]:st.set_normal(normal);st.set_color(color);st.add_vertex(p)
func _grass_mesh(kind:int)->ArrayMesh:
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in (30 if kind<4 else 18):
		var angle=rng.randf()*TAU;var reach=Vector3(cos(angle),0,sin(angle));var across=reach.cross(Vector3.UP)
		var base=Vector3(rng.randf_range(-.35,.35),0,rng.randf_range(-.35,.35));var height=rng.randf_range(.25,.72) if kind<4 else rng.randf_range(.75,1.18)
		var width=rng.randf_range(.009,.021) if kind<4 else .018
		var color=Color(.055,.12,.025).lerp(Color(.18,.22,.06),rng.randf()*.6)
		for segment in 5:
			var t=float(segment)/5;var u=float(segment+1)/5
			var a=base+Vector3.UP*height*t+reach*t*t*height*.52;var b=base+Vector3.UP*height*u+reach*u*u*height*.52
			var wa=across*width*(1-t*.92);var wb=across*width*(1-u*.98)
			_triangle(st,a-wa,b-wb,a+wa,color);_triangle(st,a+wa,b-wb,b+wb,color.lightened(.035))
	st.index();return st.commit()
func _leaf(st:SurfaceTool,start:Vector3,end:Vector3,width:float,color:Color):
	var across=(end-start).cross(Vector3.UP).normalized()
	for segment in 4:
		var t=float(segment)/4;var u=float(segment+1)/4
		var a=start.lerp(end,t)+Vector3.UP*sin(t*PI)*.025;var b=start.lerp(end,u)+Vector3.UP*sin(u*PI)*.025
		var wa=across*width*pow(sin(t*PI),.75);var wb=across*width*pow(sin(u*PI),.75)
		var ridge_a=a+Vector3.UP*wa.length()*.22;var ridge_b=b+Vector3.UP*wb.length()*.22
		_leaf_triangle(st,a-wa,b-wb,ridge_a,Vector2(0,t),Vector2(0,u),Vector2(.5,t),color)
		_leaf_triangle(st,ridge_a,b-wb,ridge_b,Vector2(.5,t),Vector2(0,u),Vector2(.5,u),color)
		_leaf_triangle(st,ridge_a,ridge_b,a+wa,Vector2(.5,t),Vector2(.5,u),Vector2(1,t),color)
		_leaf_triangle(st,a+wa,ridge_b,b+wb,Vector2(1,t),Vector2(.5,u),Vector2(1,u),color)
func _leaf_triangle(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,ua:Vector2,ub:Vector2,uc:Vector2,color:Color):
	var normal=(b-a).cross(c-a).normalized()
	var points=[a,b,c];var uvs=[ua,ub,uc]
	for i in 3:st.set_uv(uvs[i]);st.set_normal(normal);st.set_color(Color(color,.5));st.add_vertex(points[i])
func _stem(st:SurfaceTool,a:Vector3,b:Vector3,radius:float):
	var axis=(b-a).normalized();var side=axis.cross(Vector3.RIGHT).normalized();var other=axis.cross(side)
	for i in 6:
		var p=(side*cos(i*TAU/6)+other*sin(i*TAU/6))*radius;var q=(side*cos((i+1)*TAU/6)+other*sin((i+1)*TAU/6))*radius
		st.set_uv(Vector2.ZERO);_triangle(st,a+p,b+p*.8,a+q,Color(.045,.035,.018));_triangle(st,a+q,b+p*.8,b+q*.8,Color(.045,.035,.018))
func _fern_mesh()->ArrayMesh:
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for frond in 9:
		var angle=float(frond)*TAU/9;var out=Vector3(cos(angle),0,sin(angle));var across=out.cross(Vector3.UP)
		for i in 9:
			var t=float(i+1)/10;var base=out*t*.68+Vector3.UP*(sin(t*PI*.85)*.40+.10)
			var previous_t=float(i)/10;var previous=out*previous_t*.68+Vector3.UP*(sin(previous_t*PI*.85)*.40+.10)
			_stem(st,previous,base,.006)
			for side in [-1,1]:_leaf(st,base,base+across*side*sin(t*PI)*.19-out*.07,.028*sin(t*PI),Color(.035,.095,.018).lightened(float(i)*.003))
	st.index();return st.commit()
func _bush_mesh()->ArrayMesh:
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for branch in 12:
		var angle=rng.randf()*TAU;var out=Vector3(cos(angle),0,sin(angle));var height=rng.randf_range(.5,1.0)
		for i in 14:
			var t=float(i)/14;var start=Vector3.UP*(.1+t*height)+out*t*.5
			var next_t=float(i+1)/14;_stem(st,start,Vector3.UP*(.1+next_t*height)+out*next_t*.5,.014*(1-t*.8))
			var leaf_dir=out.rotated(Vector3.UP,(-1 if i%2 else 1)*.95)
			_leaf(st,start,start+leaf_dir*.16+Vector3.UP*.05,.045,Color(.045,.095,.018).lerp(Color(.10,.16,.04),rng.randf()))
	st.index();return st.commit()
func _deadwood():
	for bank in [true,false]:
		for i in 16:
			var x=rng.randf_range(6.3,26)*(-1 if i%2 else 1);var z=rng.randf_range(6,41) if bank else rng.randf_range(-120,-84)
			var root=Node3D.new();add_child(root);root.transform=_at(Vector3(x,0,z),bank,1)
			for branch in 3:
				var mesh=MeshInstance3D.new();var tube=CylinderMesh.new();tube.top_radius=.018;tube.bottom_radius=.055;tube.height=rng.randf_range(.9,2.2);tube.radial_segments=7;mesh.mesh=tube;mesh.material_override=mission.world.wood;root.add_child(mesh);mesh.position=Vector3(0,.1,0);mesh.rotation=Vector3(PI/2,0,float(branch)*.6)
