extends "res://game/remaster/world.gd"

# The original world remains intact. The second gap removes both the visible
# deck mesh and its sibling collision body; repairs own matched mesh/body pairs.
var v2_gaps:Array[Dictionary]=[
	{"index":0,"title":"第一处缺板","center":Vector3(0,-.085,-9.5),"size":Vector3(.98,.15,2.72),"approach":Vector3(0,0,-7.55),"station":Vector3(4.2,0,6.4),"alignment":"lateral"},
	{"index":1,"title":"侧索旁的斜口","center":Vector3(.65,-.085,-28.91),"size":Vector3(.98,.15,2.72),"approach":Vector3(.65,0,-26.85),"station":Vector3(0,0,-23.4),"alignment":"lateral_depth"}
]
var v2_patches:Array[Node3D]=[]
var v2_bodies:Array[StaticBody3D]=[]
var v2_repaired:Array[bool]=[false,false]

func _build_riverbanks():
	# The chapter owns the editable banks. Standalone world instances load the same scene.
	if not mission or not mission.riverbanks:
		add_child(preload("res://game/v2/riverbanks/riverbanks.tscn").instantiate())

func _bridge():
	super._bridge()
	for child in get_children():
		if not child is Node3D: continue
		if child.position.z>=-27.7 or child.position.z<=-30.12: continue
		if child is MeshInstance3D and child.mesh is BoxMesh and child.mesh.size.is_equal_approx(Vector3(3.45,.14,.46)):
			child.free()
		elif child is StaticBody3D:
			for collider in child.get_children():
				if collider is CollisionShape3D and collider.shape is BoxShape3D and collider.shape.size.is_equal_approx(Vector3(3.45,.14,.46)):
					child.free()
					break
	for i in 2:
		var patch=Node3D.new(); patch.name="V2BridgePatch%d"%i
		add_child(patch); patch.position=v2_gaps[i].center
		var mesh=MeshInstance3D.new(); var shape_mesh=BoxMesh.new()
		shape_mesh.size=v2_gaps[i].size; mesh.mesh=shape_mesh; mesh.material_override=wood; patch.add_child(mesh)
		var body=StaticBody3D.new(); body.collision_layer=0; body.collision_mask=0
		patch.add_child(body)
		var collider=CollisionShape3D.new(); var shape=BoxShape3D.new(); shape.size=v2_gaps[i].size
		collider.shape=shape; body.add_child(collider)
		v2_patches.append(patch); v2_bodies.append(body); patch.hide()

func _board():
	super._board()
	board.hide()
	repair_body.collision_layer=0

func _props():
	super._props()
	# Decorative loose scraps must not visually bridge the new physical gap.
	for child in get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh and child.position.z< -27.7 and child.position.z> -30.12 and child.position.y<.2 and child.mesh.size.x<1.0:
			child.free()

func get_v2_gap(site:int)->Dictionary:
	return v2_gaps[clampi(site,0,1)].duplicate(true)

func set_v2_repair(site:int,enabled:bool):
	if site<0 or site>=v2_patches.size(): return
	v2_repaired[site]=enabled
	v2_patches[site].visible=enabled
	v2_bodies[site].collision_layer=1 if enabled else 0
	if site==0:
		repair_enabled=enabled
		if repair_body: repair_body.collision_layer=0

func v2_repair_is_enabled(site:int)->bool:
	return site>=0 and site<v2_patches.size() and v2_repaired[site] and v2_patches[site].visible and v2_bodies[site].collision_layer==1

func enable_repair(): set_v2_repair(0,true)

func reset_board():
	super.reset_board()
	board.hide()
	for i in v2_patches.size(): set_v2_repair(i,false)

# Keep the map table, flags, buildings and terrain; remove loose decorative scraps.
# Collision bodies are siblings of the box meshes in the original generator.
func _ready():
	super._ready()
	for child in get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var size_value=child.mesh.size
			if size_value.y<.09 and size_value.x<.8 and child.position.z< -18 and child.position.y<.1:
				child.queue_free()
