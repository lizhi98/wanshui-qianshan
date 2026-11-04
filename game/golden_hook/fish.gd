extends Node3D
const P=preload("res://game/golden_hook/props.gd")
var tail:Node3D
var clock:=0.0
var speed:=1.0
var shadow:=false
var mission
func _ready():
	var model=load("res://assets/golden_hook/models/grassland_fish.glb").instantiate();add_child(model)
	tail=model.find_child("TailPivot",true,false)
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		if "FishBody" in str(mesh.name):
			var skin=ShaderMaterial.new();skin.shader=load("res://game/golden_hook/fish_skin.gdshader");skin.set_shader_parameter("shadow",1.0 if shadow else 0.0);mesh.material_override=skin
		else:
			var source=mesh.get_active_material(0)
			if source is StandardMaterial3D:
				var material=source.duplicate();material.cull_mode=BaseMaterial3D.CULL_DISABLED;mesh.material_override=material
	var ancestor=get_parent()
	while ancestor:
		if ancestor.get("mission"):mission=ancestor.mission;break
		ancestor=ancestor.get_parent()
func _process(delta):
	if mission and mission.paused:return
	clock+=delta
	if tail: tail.rotation.y=sin(clock*9*speed)*.45
