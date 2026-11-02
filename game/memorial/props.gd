extends RefCounted
static func mat(color:Color)->StandardMaterial3D:
	var m=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.96;return m
static func mesh(parent:Node3D,shape:Mesh,point:Vector3,color:Color)->MeshInstance3D:
	var n=MeshInstance3D.new();n.mesh=shape;n.material_override=mat(color);parent.add_child(n);n.position=point;return n
static func box(parent:Node3D,size:Vector3,point:Vector3,color:Color)->MeshInstance3D:
	var m=BoxMesh.new();m.size=size;return mesh(parent,m,point,color)
static func bundle(parent:Node3D)->Node3D:
	var n=Node3D.new();parent.add_child(n);n.name="CottonClothesParcel"
	var m=CapsuleMesh.new();m.radius=.16;m.height=.65;m.radial_segments=16;m.rings=5
	var roll=mesh(n,m,Vector3.ZERO,Color("77715a"));roll.rotation.z=PI/2;roll.scale.z=1.15
	for x in [-.19,.19]:
		var tie=TorusMesh.new();tie.inner_radius=.158;tie.outer_radius=.17;tie.rings=20;tie.ring_segments=6
		var cord=mesh(n,tie,Vector3(x,0,0),Color("b5a07a"));cord.rotation.z=PI/2
	return n
static func ledger(parent:Node3D)->Node3D:
	var n=Node3D.new();parent.add_child(n);n.name="WornSupplyLedger"
	box(n,Vector3(.22,.035,.31),Vector3.ZERO,Color("594435"));box(n,Vector3(.19,.025,.28),Vector3(0,.022,0),Color("c2b38b"))
	for z in [-.07,0,.07]:box(n,Vector3(.13,.002,.004),Vector3(0,.037,z),Color("77705a"))
	return n
