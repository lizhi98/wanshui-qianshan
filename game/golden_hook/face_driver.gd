extends RefCounted
## Small chapter-owned mouth morph, preserving every imported skin/shape array.
static func add_speech(mesh:MeshInstance3D,eye_center:Vector3):
	var original=mesh.mesh
	if original.get_blend_shape_count()<1: return
	var result=ArrayMesh.new(); result.blend_shape_mode=Mesh.BLEND_SHAPE_MODE_NORMALIZED
	for i in original.get_blend_shape_count(): result.add_blend_shape(original.get_blend_shape_name(i))
	result.add_blend_shape("Grass_Speech")
	for surface in original.get_surface_count():
		var arrays=original.surface_get_arrays(surface)
		var rest_uv=PackedVector2Array(); var rest_depth=PackedColorArray()
		for v in arrays[Mesh.ARRAY_VERTEX]: rest_uv.append(Vector2(v.x,v.y)); rest_depth.append(Color(v.z+.5,1,1,1))
		arrays[Mesh.ARRAY_TEX_UV2]=rest_uv; arrays[Mesh.ARRAY_COLOR]=rest_depth
		var shapes=original.surface_get_blend_shape_arrays(surface)
		if original.blend_shape_mode==Mesh.BLEND_SHAPE_MODE_RELATIVE:
			for shape in shapes:
				for channel in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT]:
					if shape[channel]!=null and arrays[channel]!=null:
						for i in shape[channel].size(): shape[channel][i]+=arrays[channel][i]
		var speech=[]; speech.resize(Mesh.ARRAY_MAX)
		var vertices=arrays[Mesh.ARRAY_VERTEX].duplicate()
		var mouth_y=eye_center.y-.055
		for i in vertices.size():
			var v=vertices[i]
			var front=smoothstep(eye_center.z-.012,eye_center.z+.012,v.z)
			var weight=exp(-pow(v.x/.032,2)-pow((v.y-mouth_y)/.014,2))*front
			v.y+=weight*(-.0065 if v.y<mouth_y else .0015)
			v.z+=weight*.0008; vertices[i]=v
		speech[Mesh.ARRAY_VERTEX]=vertices
		for channel in [Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT]:
			if arrays[channel]!=null: speech[channel]=arrays[channel].duplicate()
		shapes.append(speech)
		result.add_surface_from_arrays(original.surface_get_primitive_type(surface),arrays,shapes)
		result.surface_set_material(surface,original.surface_get_material(surface))
	mesh.mesh=result
