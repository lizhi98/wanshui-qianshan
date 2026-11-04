extends Node3D
## One continuous metal surface from needle through hook and keepsake.
var bend:=1.0
var heat:=0.0
var worn:=false
var tube:MeshInstance3D
var metal:ShaderMaterial
func _ready():
	metal=ShaderMaterial.new();metal.shader=load("res://game/golden_hook/hook_metal.gdshader")
	tube=MeshInstance3D.new();tube.name="ContinuousNeedleMetal";tube.material_override=metal;add_child(tube)
	var eye=MeshInstance3D.new();var torus=TorusMesh.new();torus.inner_radius=.00165;torus.outer_radius=.0031;torus.rings=32;torus.ring_segments=12;eye.mesh=torus;eye.material_override=metal;add_child(eye);eye.position.y=.058;eye.rotation.x=PI/2
	_rebuild();_material()
func set_bend(value:float):
	bend=clampf(value,0,1)
	if tube:_rebuild()
func set_heat(value:float):heat=clampf(value,0,1);_material()
func set_worn(value:bool):worn=value;_material()
func _material():
	if metal:metal.set_shader_parameter("heat",heat);metal.set_shader_parameter("worn",1.0 if worn else 0.0)
func _rebuild():
	var curved=PackedVector3Array([Vector3(0,.055,0),Vector3(0,.013,0)])
	for i in 33:
		var a=PI+i/32.0*PI*1.03;curved.append(Vector3(.012+cos(a)*.012,.013+sin(a)*.013,0))
	curved.append(Vector3(.023,.027,0))
	var points=PackedVector3Array();var length=0.0
	for i in curved.size():
		if i>0:length+=curved[i].distance_to(curved[i-1])
		points.append(Vector3(0,.055-length,0).lerp(curved[i],bend))
	var rings=[]
	for i in points.size():
		var direction=(points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]).normalized()
		var across=direction.cross(Vector3.BACK).normalized();var ring=[]
		var radius=.0016*lerpf(1.0,.12,smoothstep(points.size()-4,points.size()-1,i))
		for side in 12:var a=side*TAU/12;ring.append(points[i]+(across*cos(a)+Vector3.BACK*sin(a))*radius)
		rings.append(ring)
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rings.size()-1:
		for j in 12:
			var k=(j+1)%12
			for v in [rings[i][j],rings[i+1][j],rings[i][k],rings[i][k],rings[i+1][j],rings[i+1][k]]:st.add_vertex(v)
	st.generate_normals();st.index();tube.mesh=st.commit()
