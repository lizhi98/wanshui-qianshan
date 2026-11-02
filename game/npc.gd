extends CharacterBody3D

signal defeated

var visual
var mission
var enemy := false
var health := 100
var dead := false
var route: Array = []
var route_index := 0
var moving := false
var moving_speed := 1.85
var start_position: Vector3
var cooldown := 1.5
var suppression := 0.0
var fixed_pose := ""
var visual_type: Script = preload("res://game/soldier_visual.gd")
var chain_from := -16.85
var chain_to := -21.0
var mobile_cover := false
var cover_time := 0.0

func _ready():
	collision_layer = 4 if enemy else 8
	collision_mask = 1
	var collider = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.height = 1.74
	capsule.radius = 0.29
	collider.shape = capsule
	collider.position.y = 0.87
	add_child(collider)
	visual = visual_type.new()
	visual.uniform = Color("807453") if enemy else (Color("52666b") if name == "Zhou" else Color("687b7b"))
	add_child(visual)
	start_position = position

func walk(points: Array, speed := 1.85):
	route = points
	route_index = 0
	moving = not route.is_empty()
	moving_speed = speed
	fixed_pose = ""

func _physics_process(delta):
	if dead or mission.paused or mission.failed:
		return
	suppression = maxf(0, suppression-delta)
	if moving:
		var goal = route[route_index]
		var difference = goal-position
		difference.y = 0
		if difference.length()<0.1:
			route_index += 1
			if route_index>=route.size():
				moving = false
				visual.speed = 0
				visual.mode = "idle"
		else:
			# Authored safe bridge paths. Short final chain segment uses scripted foot placement.
			position += difference.normalized()*minf(moving_speed*delta, difference.length())
			rotation.y = lerp_angle(rotation.y, Vector2(difference.z, difference.x).angle(), minf(10*delta,1))
			visual.mode = "walk"
			visual.speed = moving_speed
			if position.z < chain_from and position.z > chain_to:
				visual.mode = "climb"
				rotation.y = PI/2
	elif not fixed_pose.is_empty():
		visual.mode = fixed_pose
	else:
		visual.mode = "idle"
		visual.speed = 0
	if mission.phase == mission.Phase.COMBAT:
		if enemy:
			if mobile_cover:
				cover_time+=delta
				position.x=move_toward(position.x,start_position.x+sin(cover_time*.9)*.28,delta*.35)
			face(mission.player.position)
			visual.mode = "aim"
			cooldown -= delta
			if cooldown <= 0 and suppression <= 0:
				cooldown = 1.7+randf()*0.6
				mission.combat.fire_enemy(self)
		elif name == "Zhou":
			visual.mode = "aim"
			face(mission.enemies[0].position if not mission.enemies.is_empty() else Vector3(2.5,0,-28))
			cooldown -= delta
			if cooldown <= 0:
				cooldown = 2.8
				mission.combat.fire_ally(self)

func face(point: Vector3):
	var direction = point-position
	if direction.length()>0.01:
		rotation.y = Vector2(direction.z, direction.x).angle()

func damage(amount):
	if dead:
		return
	health = maxi(0, health-int(amount))
	suppression = 0.85
	visual.hurt()
	mission.sound("res://assets/audio/enemy_hurt.ogg", -15)
	if health <= 0:
		dead = true
		moving = false
		visual.mode = "dead"
		collision_layer = 0
		defeated.emit()

func restore():
	health = 100
	dead = false
	moving = false
	position = start_position
	collision_layer = 4 if enemy else 8
	cooldown = 1.5
	suppression = 0
	fixed_pose = ""
	visual.reset_pose()
