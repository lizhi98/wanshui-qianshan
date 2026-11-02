extends Node3D
enum Phase { INTRO, COMBAT, PICKUP, COOPERATE, CROSSING, ENDING }
var phase=Phase.CROSSING
var paused=false
var failed=false
var started=true
var player
var amu
var zhou
var world:Node3D
var view:Node3D
var combat={"aim_assist":true,"reloading":false}
var traversal
var saves=0
var remarks:Array=[]
class Visual extends Node3D:
	var mode="idle"
	var speed=0.0
	var uniform=Color.WHITE
	var armed=false
	var hand_targets:Array=[]
	func reset_pose(): mode="idle"
	func hurt(): pass
func _ready():
	for action in ["interact","observe","signal","jump"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	world=Node3D.new(); add_child(world)
	view=Node3D.new(); add_child(view)
	var camera=Camera3D.new(); camera.name="Camera"; view.add_child(camera)
	_floor(Vector3(0,-.15,-53.3),Vector3(3.4,.3,3))
	_floor(Vector3(0,-.15,-73.1),Vector3(7,.3,22))
	player=load("res://objects/player.tscn").instantiate()
	player.set_script(load("res://game/v2/player.gd"))
	player.mission=self
	player.visual_type=Visual
	player.position=Vector3(1.43,.05,-54.3)
	add_child(player)
	player.view=view
	player.set_physics_process(false)
	for label in ["Amu","Zhou"]:
		var actor=load("res://game/npc.gd").new()
		actor.name=label; actor.mission=self; actor.visual_type=Visual
		actor.position=Vector3(.4 if label=="Amu" else -.4,0,-53.6)
		add_child(actor)
		if label=="Amu": amu=actor
		else: zhou=actor
func _floor(pos:Vector3,size_value:Vector3):
	var body=StaticBody3D.new(); body.collision_layer=1
	var shape=CollisionShape3D.new(); shape.shape=BoxShape3D.new(); shape.shape.size=size_value
	body.add_child(shape); world.add_child(body); body.position=pos
func sound(_path:String,_volume:float): pass
func say(who:String,line:String): remarks.append(who+line)
func save_checkpoint(): saves+=1
func on_chain_finished(): pass
