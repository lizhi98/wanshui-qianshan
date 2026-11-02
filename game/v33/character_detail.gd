extends RefCounted
static func apply(visual,variant:String):
	var shader=load("res://game/v33/cloth.gdshader")
	var normal=load("res://assets/remaster/characters/"+variant+"_male_casualsuit01_normal.png")
	for mesh in visual.rig.find_children("*","MeshInstance3D",true,false):
		var source=mesh.get_active_material(0)
		if not source is StandardMaterial3D:continue
		var label=str(source.resource_name).to_lower()
		if "cotton" in label or "canvas" in label or "leather" in label or "cloth shoes" in label:
			var cloth=ShaderMaterial.new();cloth.shader=shader
			var color=source.albedo_color
			if "defender" in str(visual.get_parent().name).to_lower() and "cotton" in label:color=Color("665d46")
			cloth.set_shader_parameter("cloth_color",color);cloth.set_shader_parameter("cloth_normal",normal)
			cloth.set_shader_parameter("use_normal",1.0 if "Tailored" in str(mesh.name) else 0.0)
			mesh.material_override=cloth
	var attachment=BoneAttachment3D.new();attachment.name="PackWebbingAndBuckles";visual.skeleton.add_child(attachment);attachment.bone_name="spine_03"
	var index=visual.skeleton.find_bone("spine_03");var rest=visual.skeleton.get_bone_global_rest(index).affine_inverse()
	var leather=StandardMaterial3D.new();leather.albedo_color=Color("524c36");leather.roughness=.97
	var metal=StandardMaterial3D.new();metal.albedo_color=Color("48463a");metal.metallic=.45;metal.roughness=.72
	for side in [-1,1]:
		for entry in [[Vector3(.018,.31,.009),Vector3(side*.096,1.275,-.226)],[Vector3(.018,.018,.16),Vector3(side*.096,1.5,-.16)]]:
			var mesh=MeshInstance3D.new();mesh.mesh=BoxMesh.new();mesh.mesh.size=entry[0];mesh.material_override=leather;attachment.add_child(mesh);mesh.transform=rest*Transform3D(Basis.IDENTITY,entry[1])
		var buckle=MeshInstance3D.new();buckle.mesh=TorusMesh.new();buckle.mesh.inner_radius=.012;buckle.mesh.outer_radius=.016;buckle.mesh.rings=12;buckle.mesh.ring_segments=5;buckle.material_override=metal;attachment.add_child(buckle);buckle.transform=rest*Transform3D(Basis(Vector3.RIGHT,PI/2),Vector3(side*.096,1.20,-.235))
