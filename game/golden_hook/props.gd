extends RefCounted
## Chapter-owned meshes; all dimensions are in metres.
static func mat(hex:String,rough:=.8)->StandardMaterial3D:
	var m=StandardMaterial3D.new(); m.albedo_color=Color(hex); m.roughness=rough
	return m
static func mesh(parent:Node3D,shape:Mesh,pos:Vector3,material:Material)->MeshInstance3D:
	var n=MeshInstance3D.new(); n.mesh=shape; n.material_override=material
	parent.add_child(n); n.position=pos
	return n
static func box(parent:Node3D,size:Vector3,pos:Vector3,color:String)->MeshInstance3D:
	var shape=BoxMesh.new(); shape.size=size
	return mesh(parent,shape,pos,mat(color))
static func ellipsoid(parent:Node3D,size:Vector3,pos:Vector3,color:String)->MeshInstance3D:
	var shape=SphereMesh.new(); shape.radius=.5; shape.height=1; shape.radial_segments=16; shape.rings=8
	var n=mesh(parent,shape,pos,mat(color)); n.scale=size
	return n
static func cylinder(parent:Node3D,a:Vector3,b:Vector3,radius:float,material:Material)->MeshInstance3D:
	var shape=CylinderMesh.new(); shape.top_radius=radius*.9; shape.bottom_radius=radius; shape.height=a.distance_to(b); shape.radial_segments=10
	var n=mesh(parent,shape,(a+b)*.5,material)
	var direction=(b-a).normalized()
	n.quaternion=Quaternion(Vector3.UP,direction)
	return n
static func polyline(parent:Node3D,points:PackedVector3Array,radius:float,material:Material)->Node3D:
	var n=Node3D.new(); parent.add_child(n)
	for i in points.size()-1:
		if points[i].distance_squared_to(points[i+1])>.00000001: cylinder(n,points[i],points[i+1],radius,material)
	return n
static func bowl(parent:Node3D,with_soup:=true)->Node3D:
	var n=Node3D.new(); n.name="EnamelBowl"; parent.add_child(n)
	var st=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile=[Vector2(.065,0),Vector2(.09,.025),Vector2(.115,.09),Vector2(.117,.105)]
	for j in profile.size()-1:
		for i in 32:
			var a=float(i)/32*TAU; var b=float(i+1)/32*TAU
			var p=Vector3(cos(a)*profile[j].x,profile[j].y,sin(a)*profile[j].x)
			var q=Vector3(cos(b)*profile[j].x,profile[j].y,sin(b)*profile[j].x)
			var r=Vector3(cos(b)*profile[j+1].x,profile[j+1].y,sin(b)*profile[j+1].x)
			var s=Vector3(cos(a)*profile[j+1].x,profile[j+1].y,sin(a)*profile[j+1].x)
			for v in [p,q,r,p,r,s]: st.add_vertex(v)
	st.generate_normals()
	var enamel=mat("c9d0bf",.27); enamel.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh(n,st.commit(),Vector3.ZERO,enamel)
	var rim=TorusMesh.new(); rim.inner_radius=.109; rim.outer_radius=.12; rim.rings=24; rim.ring_segments=8
	mesh(n,rim,Vector3(0,.103,0),mat("354d54",.22))
	if with_soup:
		var liquid=CylinderMesh.new(); liquid.top_radius=.105; liquid.bottom_radius=.105; liquid.height=.006
		mesh(n,liquid,Vector3(0,.084,0),mat("8d8a5c",.22))
	return n
static func hook(parent:Node3D,curvature:=1.0,worn:=false)->Node3D:
	var n=load("res://game/golden_hook/needle_hook.gd").new();n.name="PersistentNeedleHook";n.bend=curvature;n.worn=worn;parent.add_child(n);return n
static func parcel(parent:Node3D)->Node3D:
	var n=load("res://assets/golden_hook/models/keepsake_cloth.glb").instantiate();n.name="KeepsakeCloth";parent.add_child(n);return n
static func set_wrap(cloth_parcel:Node3D,value:float):
	for mesh_instance in cloth_parcel.find_children("*","MeshInstance3D",true,false):
		var shape=mesh_instance.find_blend_shape_by_name("Wrapped")
		if shape>=0:mesh_instance.set_blend_shape_value(shape,clampf(value,0,1))

static func camp_model(parent:Node3D,id:String,pos:=Vector3.ZERO)->Node3D:
	var n=load("res://assets/golden_hook/models/"+id+".glb").instantiate();parent.add_child(n);n.position=pos
	for mesh_instance in n.find_children("*","MeshInstance3D",true,false):
		var source=mesh_instance.get_active_material(0)
		if source is StandardMaterial3D:
			var label=str(source.resource_name).to_lower()
			if "cotton" in label or "canvas" in label or "blanket" in label or "wool" in label:
				var cloth=ShaderMaterial.new();cloth.shader=load("res://game/golden_hook/prop_cloth.gdshader");cloth.set_shader_parameter("cloth_color",source.albedo_color);cloth.set_shader_parameter("use_normal",0.0);mesh_instance.material_override=cloth
	return n
static func sack(parent:Node3D,pos:Vector3)->Node3D:return camp_model(parent,"ration_sack",pos)

static func greens(parent:Node3D,pos:Vector3)->Node3D:
	var n=Node3D.new(); parent.add_child(n); n.position=pos
	for i in 6:
		var a=i*TAU/6
		var leaf=ellipsoid(n,Vector3(.055,.22,.025),Vector3(sin(a)*.05,.09,cos(a)*.05),"71805b")
		leaf.rotation=Vector3(cos(a)*.5,a,sin(a)*.5)
	return n
static func tent(parent:Node3D,pos:Vector3):return camp_model(parent,"canvas_shelter",pos)
