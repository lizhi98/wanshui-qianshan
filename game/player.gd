# Derived from Kenney Starter Kit 3D Platformer player.gd (MIT).
# Keeps camera-relative input, velocity smoothing, CharacterBody sliding and gravity.
extends "res://scripts/player.gd"

signal died
signal hit

var visual
var health := 100
var locked := true
var carrying := false
var climbing := false
var aiming := false
var mission
var climb_progress := 0.0
var balance := 0.0
var step_time := 0.0
var visual_type: Script = preload("res://game/soldier_visual.gd")
var chain_from := -16.35
var chain_to := -21.0
var chain_duration := 7.2

func _ready():
	$Character.hide()
	visual = visual_type.new()
	visual.name = "Soldier"
	add_child(visual)
	$ParticlesTrail.emitting = false
	$SoundFootsteps.stop()
	$Collider.shape = CapsuleShape3D.new()
	$Collider.shape.radius = 0.27
	$Collider.shape.height = 1.73
	$Collider.position.y = 0.86
	collision_layer = 2
	collision_mask = 1
	jump_strength = 6.1

func _physics_process(delta):
	if climbing:
		_climb(delta)
		return
	if locked:
		movement_velocity = Vector3.ZERO
		visual.speed=0
		velocity = Vector3.ZERO
		return
	handle_controls(delta)
	handle_gravity(delta)
	# Retained Kenney velocity interpolation; speeds now use metres/second.
	var applied_velocity = velocity.lerp(movement_velocity, minf(delta*10, 1.0))
	applied_velocity.y = -gravity
	if carrying and mission.get("repair") and mission.repair.active:
		applied_velocity=mission.repair.filter_carry_velocity(applied_velocity,delta)
	velocity = applied_velocity
	move_and_slide()
	if aiming:
		rotation_direction = view.rotation.y+PI
	elif Vector2(velocity.z, velocity.x).length() > 0.08:
		rotation_direction = Vector2(velocity.z, velocity.x).angle()
	rotation.y = lerp_angle(rotation.y, rotation_direction, minf(delta*10, 1.0))
	handle_effects(delta)
	if position.y < -5.0:
		damage(1000)
	previously_floored = is_on_floor()

var free_walk_speed := 3.1
var free_run_speed := 4.8

func handle_controls(_delta):
	var input = Vector3(Input.get_axis("move_left", "move_right"), 0, Input.get_axis("move_forward", "move_back"))
	input = input.rotated(Vector3.UP, view.rotation.y).limit_length(1.0)
	var speed = free_walk_speed
	if Input.is_action_pressed("sprint") and not aiming and not carrying:
		speed = free_run_speed
	if carrying: speed = 1.65
	if aiming: speed = 1.8
	movement_velocity = input*speed
	if Input.is_action_just_pressed("jump") and is_on_floor() and not carrying:
		jump()

func handle_effects(delta):
	var horizontal = Vector2(velocity.x, velocity.z).length()
	visual.speed = horizontal
	if carrying:
		visual.mode = "carry"
	elif mission.combat.reloading:
		visual.mode = "reload"
	elif not is_on_floor():
		visual.mode = "jump"
	elif aiming:
		visual.mode = "aim"
	elif horizontal > 3.4:
		visual.mode = "run"
	elif horizontal > 0.1:
		visual.mode = "walk"
	else:
		visual.mode = "idle"
	step_time += delta
	if get_position_delta().length() > delta*.4 and is_on_floor() and step_time > (0.3 if horizontal>3.4 else 0.48):
		step_time = 0.0
		mission.sound("res://sounds/land.ogg", -24)

func jump():
	gravity = -jump_strength
	jump_single = false
	jump_double = false
	mission.sound("res://sounds/jump.ogg", -18)

func damage(amount):
	if health <= 0 or locked or mission.failed:
		return
	health = maxi(0, health-int(amount))
	visual.hurt()
	hit.emit()
	if health == 0:
		locked = true
		visual.mode = "dead"
		died.emit()

func start_climb():
	climbing = true
	carrying = false
	climb_progress = 0.0
	balance = 0.0
	velocity = Vector3.ZERO
	visual.mode = "climb"
	rotation.y = PI/2

func _climb(delta):
	if locked:
		return
	var forward = -Input.get_axis("move_forward", "move_back")
	climb_progress = clampf(climb_progress+forward*delta/chain_duration, 0.0, 1.0)
	var correction = Input.get_axis("move_left", "move_right")
	balance = clampf(balance+(sin(climb_progress*TAU*1.7)*0.28+correction*0.55)*delta, -1.1, 1.1)
	position = Vector3(1.43, -0.04+sin(climb_progress*PI)*0.06, lerpf(chain_from, chain_to, climb_progress))
	visual.rotation.z = sin(Time.get_ticks_msec()*0.003)*0.04+balance*0.14
	visual.speed = absf(forward)*1.4
	if absf(balance)>1.0:
		climbing = false
		damage(1000)
	elif climb_progress >= 1.0:
		climbing = false
		visual.rotation.z = 0
		visual.mode = "idle"
		position.y = 0.12
		mission.on_chain_finished()

func restore(pos: Vector3):
	health = 100
	position = pos
	velocity = Vector3.ZERO
	movement_velocity = Vector3.ZERO
	gravity = 0.0
	locked = false
	carrying = false
	climbing = false
	visual.rotation = Vector3.ZERO
	visual.reset_pose()
