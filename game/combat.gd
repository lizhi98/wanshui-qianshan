# Third-person adaptation of Kenney FPS ray hit/damage/cooldown and recoil (MIT).
extends Node

var mission
var ammo := 5
var reserve := 30
var cooldown := 0.0
var reloading := false
var reload_time := 0.0
var shots := 0
var hit_count := 0
var max_range := 70.0
var enemy_range := 65.0
var aim_assist := false
var enemy_damage := 7
var player_shot_sound := "res://assets/audio/rifle.wav"
var player_shot_volume_db := -10.0

func _process(delta):
	if mission.paused or mission.failed:
		return
	cooldown = maxf(0, cooldown-delta)
	if reloading:
		reload_time -= delta
		if reload_time <= 0:
			var amount = mini(5-ammo, reserve)
			ammo += amount
			reserve -= amount
			reloading = false
	if can_use_weapon():
		mission.player.aiming = Input.is_action_pressed("aim")
		if Input.is_action_pressed("shoot"):
			fire_player()
		if Input.is_action_just_pressed("reload") and (mission.phase==mission.Phase.COMBAT or mission.player.aiming):
			reload()
	else:
		mission.player.aiming = false
	if mission.get("assault") and mission.assault.active:
		mission.player.visual.armed=mission.player.aiming and not mission.player.carrying

func can_use_weapon() -> bool:
	return (mission.phase == mission.Phase.COMBAT or (mission.get("assault") and mission.assault.active)) and not mission.dialogue_locked and not mission.player.locked and not mission.player.carrying and not mission.player.climbing and not mission.failed and not mission.paused

func reload():
	if not can_use_weapon() or reloading or ammo == 5 or reserve == 0:
		return
	reloading = true
	reload_time = 2.15
	mission.sound("res://assets/audio/weapon_change.ogg", -14)

func ray(from: Vector3, to: Vector3, mask: int) -> Dictionary:
	var query = PhysicsRayQueryParameters3D.create(from, to, mask)
	return mission.get_world_3d().direct_space_state.intersect_ray(query)

func fire_player() -> bool:
	if not can_use_weapon() or cooldown>0 or reloading or ammo<=0:
		return false
	ammo -= 1
	shots += 1
	cooldown = 0.78
	var camera = mission.view.camera
	var screen_center = mission.get_viewport().get_visible_rect().size*0.5
	var origin = camera.project_ray_origin(screen_center)
	var direction = camera.project_ray_normal(screen_center)
	if not mission.player.aiming:
		direction = (direction+Vector3(randf_range(-0.013,0.013),randf_range(-0.013,0.013),0)).normalized()
	if aim_assist and mission.player.aiming:
		var best=cos(deg_to_rad(1.5))
		var assisted_direction=direction
		for enemy in mission.enemies:
			if enemy.dead: continue
			var point=enemy.global_position+Vector3(0,1.30,0)
			var towards=(point-origin).normalized()
			var score=direction.dot(towards)
			if score>best:
				var obstruction=ray(origin,point,5)
				if not obstruction.is_empty() and obstruction.collider==enemy:
					best=score
					assisted_direction=towards
		direction=assisted_direction
	var target = origin+direction*max_range
	var camera_hit = ray(origin, target, 5)
	if not camera_hit.is_empty(): target = camera_hit.position
	var muzzle = mission.player.visual.muzzle.global_position
	# A second ray prevents third-person camera from firing through nearby cover.
	var hit_info = ray(muzzle, target+direction*0.08, 5)
	var end = target
	if not hit_info.is_empty():
		end = hit_info.position
		if hit_info.collider.has_method("damage"):
			hit_info.collider.damage(34)
			hit_count += 1
			mission.hud.hit_marker = 0.18
		impact(end)
	flash(muzzle)
	tracer(muzzle,end,Color("ffd39b"))
	mission.sound(player_shot_sound, player_shot_volume_db)
	mission.view.recoil()
	return true

func fire_enemy(actor):
	if not can_use_weapon() or actor.dead:
		return
	var muzzle = actor.visual.muzzle.global_position
	var target = mission.player.global_position+Vector3(0,1.22,0)
	if muzzle.distance_to(target)>enemy_range:
		return
	var hit_info = ray(muzzle,target,3)
	flash(muzzle)
	mission.sound("res://assets/audio/rifle.wav", -24)
	if not hit_info.is_empty():
		tracer(muzzle,hit_info.position,Color("f09961"))
		impact(hit_info.position)
		if hit_info.collider == mission.player:
			mission.player.damage(enemy_damage)
	else:
		tracer(muzzle,target,Color("d29d69"))

func fire_ally(actor):
	if not can_use_weapon():
		return
	var target_actor
	for enemy in mission.enemies:
		if not enemy.dead:
			target_actor = enemy
			break
	if not target_actor:
		return
	var muzzle = actor.visual.muzzle.global_position
	var target = target_actor.position+Vector3(0,1.3,0)
	var hit_info = ray(muzzle,target,5)
	flash(muzzle)
	tracer(muzzle,hit_info.position if not hit_info.is_empty() else target,Color("ffcf89"))
	mission.sound("res://assets/audio/rifle.wav", -23)
	if not hit_info.is_empty() and hit_info.collider == target_actor:
		target_actor.suppression = 1.0

func flash(position_value: Vector3):
	var node = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.065
	mesh.height = 0.13
	node.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("ffe4a8")
	mat.emission_enabled = true
	mat.emission = Color("ffaa37")
	mat.emission_energy_multiplier = 2
	node.material_override = mat
	mission.add_child(node)
	node.global_position = position_value
	var tween = node.create_tween()
	tween.tween_property(node,"scale",Vector3.ONE*0.1,0.09)
	tween.tween_callback(node.queue_free)

func tracer(from: Vector3, to: Vector3, color: Color):
	if from.distance_to(to)<0.1:
		return
	var line = ImmediateMesh.new()
	line.surface_begin(Mesh.PRIMITIVE_LINES)
	line.surface_add_vertex(from)
	line.surface_add_vertex(to)
	line.surface_end()
	var node = MeshInstance3D.new()
	node.mesh = line
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	node.material_override = mat
	mission.add_child(node)
	var tween = node.create_tween()
	tween.tween_interval(0.08)
	tween.tween_callback(node.queue_free)

func impact(position_value: Vector3):
	var node = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	node.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("bd8552")
	node.material_override = mat
	mission.add_child(node)
	node.position = position_value
	var tween = node.create_tween()
	tween.tween_property(node,"scale",Vector3.ONE*0.05,0.24)
	tween.tween_callback(node.queue_free)

func reset():
	ammo = 5
	reserve = 30
	cooldown = 0
	reloading = false
	reload_time = 0
	shots = 0
	hit_count = 0
