extends Node3D
# Presentation combat is bounded and never changes mission completion or
# destroys a required crossing. Artillery deployment is a gameplay adaptation.
var mission
var active:=false
var clock:=0.0
var guns:Array=[]
var soldiers:Array=[]
var roles:Array=[]
var shells:Array=[]
var effects:Array=[]
var smoke:Array=[]
var far_rows:Array=[]
var far_meshes:Array=[]
var shots_near:=0
var shots_far:=0
var impacts:=0
var infantry_shots:=0
var cloud:Texture2D
var sounds:Array=[]
var sound_index:=0
var far_clock:=0.0
var bridgehead_cleared:=false

func setup(m):
	mission=m; cloud=_cloud_texture()
	for i in 10:
		var audio=AudioStreamPlayer3D.new(); add_child(audio); audio.max_distance=250; audio.unit_size=12; sounds.append(audio)
	for side in [0,1]:
		for i in 2:
			var gun_x=(-9 if i==0 else 10) if side==0 else (-15 if i==0 else 16)
			_make_gun(Vector3(gun_x,0,10-i*3 if side==0 else -90-i*3),side,i)
		for i in 6:
			var p=Vector3((-1 if i%2 else 1)*(4.7+float(i)*1.45),0,(2.5+float(i%3)*2.5) if side==0 else (-82.5-float(i%3)*3.0))
			if side==1: p.z=-81.5-float(i%2)*1.5
			_add_soldier(p,side,false,i)
		_make_far_force(side)
	for p in [Vector3(-3.8,2.4,-79),Vector3(4.1,.2,-84),Vector3(-12,0,4)]:
		var stack=_particles(p,42,8.0,false,Color(.08,.075,.065,.82),2.0,6.0,2.2,3.8)
		stack.emitting=false; smoke.append(stack)
		stack.preprocess=5.0
	for p in [Vector3(-2.7,.4,-79),Vector3(3.0,.3,-80.5)]:
		var fire=_particles(p,22,1.35,false,Color(1,.38,.055,.8),.45,1.8,1.5,4.0,true)
		fire.emitting=false; smoke.append(fire)
	visible=false

func _process(delta):
	if not mission: return
	var wanted=mission.started and not mission.failed and mission.stage not in ["modern","complete"]
	if wanted and not active: start()
	elif not wanted and active: stop()
	if not active: return
	for particle in smoke: particle.speed_scale=0 if mission.paused else 1
	for effect in effects:
		for particle in effect.node.get_children():
			if particle is GPUParticles3D: particle.speed_scale=0 if mission.paused else 1
	for audio in sounds: audio.stream_paused=mission.paused
	if mission.paused: return
	clock+=delta; far_clock-=delta
	if mission.ledger.current in ["relay","modern","complete"] and not bridgehead_cleared:
		bridgehead_cleared=true
		for shell in shells: shell.node.queue_free()
		shells.clear()
		for mesh in far_meshes[1]: mesh.hide()
		for i in soldiers.size():
			if roles[i].side!=1: continue
			var actor=soldiers[i]; actor.dead=true; actor.health=0; actor.visual.mode="dead"; actor.visual.armed=false; actor.visual.speed=0
	var fighting=mission.ledger.current in ["escort","repair","traversal"] and not bridgehead_cleared
	for i in guns.size():
		var gun=guns[i]
		gun.cooldown-=delta
		gun.barrel.position.z=.42-sin(clampf((clock-float(gun.last))/.34,0,1)*PI)*.24
		if fighting and gun.cooldown<=0:
			_fire_gun(i); gun.cooldown=6.2+float(i)*.61
	_update_infantry(delta,fighting)
	if far_clock<=0: _update_far_force(); far_clock=.12
	for shell in shells.duplicate():
		shell.age+=delta; var p=clampf(float(shell.age)/float(shell.duration),0,1)
		shell.node.position=Vector3(shell.from).lerp(shell.to,p)+Vector3.UP*(4*p*(1-p)*float(shell.arc))
		if p>=1:
			_impact(shell.to,shell.side); shell.node.queue_free(); shells.erase(shell)
	for effect in effects.duplicate():
		effect.age+=delta
		if effect.age>4.5: effect.node.queue_free(); effects.erase(effect)
		elif effect.has("light"): effect.light.light_energy=maxf(0,2.2-float(effect.age)*9)

func start():
	active=true; visible=true; clock=0; far_clock=0; shots_near=0; shots_far=0; impacts=0; infantry_shots=0
	bridgehead_cleared=false
	for group in far_meshes:
		for mesh in group: mesh.show()
	for actor in soldiers: actor.dead=false; actor.health=100
	for i in guns.size(): guns[i].cooldown=1.0+float(i)*1.45; guns[i].last=-5.0
	for stack in smoke: stack.emitting=true
	for actor in soldiers: actor.show()

func stop():
	active=false; visible=false
	for stack in smoke: stack.emitting=false
	for shell in shells: shell.node.queue_free()
	for effect in effects: effect.node.queue_free()
	shells.clear(); effects.clear()
	for audio in sounds: audio.stop(); audio.stream=null
	for actor in soldiers:
		actor.hide(); actor.visual.speed=0

func _ground(p:Vector3)->Vector3:
	p.y=mission.world._ground_height(p.x,p.z,p.z> -39)+.08
	return p

func _material(color:Color,glow:=false)->StandardMaterial3D:
	var mat=StandardMaterial3D.new(); mat.albedo_color=color; mat.roughness=.85
	if glow: mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; mat.emission_enabled=true; mat.emission=color; mat.emission_energy_multiplier=3
	return mat

func _box(parent:Node,size_value:Vector3,p:Vector3,mat:Material)->MeshInstance3D:
	var node=MeshInstance3D.new(); node.mesh=BoxMesh.new(); node.mesh.size=size_value; node.position=p; node.material_override=mat; parent.add_child(node); return node

func _cylinder(parent:Node,radius:float,height:float,p:Vector3,mat:Material)->MeshInstance3D:
	var node=MeshInstance3D.new(); node.mesh=CylinderMesh.new(); node.mesh.top_radius=radius; node.mesh.bottom_radius=radius; node.mesh.height=height; node.mesh.radial_segments=16
	node.position=p; node.material_override=mat; parent.add_child(node); return node

func _make_gun(point:Vector3,side:int,index:int):
	var root=Node3D.new(); add_child(root); root.position=_ground(point); root.rotation.y=PI if side==0 else 0.0
	var iron=_material(Color("363a32")); var wood=_material(Color("514b34"))
	_box(root,Vector3(.8,.36,1.2),Vector3(0,.63,-.30),iron)
	for x in [-.72,.72]:
		var wheel=_cylinder(root,.55,.12,Vector3(x,.55,-.38),wood); wheel.rotation.z=PI/2
		var hub=_cylinder(root,.16,.18,Vector3(x,.55,-.38),iron); hub.rotation.z=PI/2
	for x in [-.29,.29]:
		var trail=_box(root,Vector3(.13,.12,2.3),Vector3(x,.25,-1.25),wood); trail.rotation.x=-.18; trail.rotation.y=x*.4
	var barrel=Node3D.new(); root.add_child(barrel); barrel.position=Vector3(0,1.05,.42); barrel.rotation.x=-.22
	var tube=_cylinder(barrel,.14,2.3,Vector3(0,0,.22),iron); tube.rotation.x=PI/2
	var muzzle=Node3D.new(); barrel.add_child(muzzle); muzzle.position=Vector3(0,0,1.42)
	guns.append({"root":root,"barrel":barrel,"muzzle":muzzle,"side":side,"cooldown":float(index+1),"last":-5.0})
	_add_soldier(point+Vector3(-.85,0,.65 if side==0 else -.65),side,true,index)
	roles[-1]["gun"]=guns.size()-1
	for i in 3: _box(root,Vector3(.6,.4,.42),Vector3(1.1,.21,-1.0-float(i)*.5),wood)

func _add_soldier(point:Vector3,side:int,crew:bool,index:int):
	var actor=mission._actor(("V31_Defender_" if side else "V31_Assault_")+str(soldiers.size()),_ground(point),side==1)
	actor.set_physics_process(false); actor.collision_layer=0; actor.collision_mask=0
	actor.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.visual.armed=not crew; actor.visual.animation_offset+=float(soldiers.size())*.31
	actor.visual.mode="brace" if crew else ("kneel_aim" if index%2 else "aim")
	soldiers.append(actor); roles.append({"base":_ground(point),"side":side,"crew":crew,"phase":float(index)*1.77,"fire":.5+float(index)*.31})
	actor.hide()

func _update_infantry(delta:float,fighting:bool):
	for i in soldiers.size():
		var actor=soldiers[i]; var role=roles[i]
		if actor.dead: actor.visual.mode="dead"; actor.visual.armed=false; continue
		if role.crew:
			var gun=guns[int(role.gun)];var sign_value=1.0 if role.side==0 else -1.0
			var base:Vector3=gun.root.position
			actor.visual.mode="kneel_aim";actor.visual.armed=false;actor.visual.speed=0
			actor.visual.hand_targets=[base+Vector3(-.52,.67,.32*sign_value),base+Vector3(-.35,.70,.50*sign_value)]
			actor.visual.look_enabled=true;actor.visual.look_target=base+Vector3(0,.9,0)
			var toward=base-actor.position;actor.rotation.y=atan2(toward.x,toward.z)
			continue
		var cycle=fmod(clock+role.phase,9.5)
		var goal:Vector3=role.base
		if cycle<2.4: goal+=Vector3(sin(role.phase)*1.3,0,-1.5 if role.side==0 else 1.5)
		var avoid=actor.position-mission.player.position; avoid.y=0
		if avoid.length()<1.55: goal+=avoid.normalized()*1.5
		goal=_ground(goal); var before=actor.position
		actor.position=before.move_toward(goal,delta*2.8)
		actor.visual.speed=actor.position.distance_to(before)/maxf(delta,.001)
		actor.visual.armed=true
		actor.visual.mode="run" if actor.visual.speed>.2 else ("kneel_aim" if i%2 else "aim")
		var target=Vector3(-float(i%3)+1,1.3,-83 if role.side==0 else 2)
		var facing=(goal-before) if actor.visual.speed>.2 else (target-actor.position)
		if facing.length()>.02: actor.rotation.y=rotate_toward(actor.rotation.y,atan2(facing.x,facing.z),delta*3.5)
		role.fire-=delta
		if fighting and role.fire<=0 and actor.visual.speed<.2:
			role.fire=1.7+fmod(float(i)*.67,1.8)
			var muzzle=actor.visual.muzzle.global_position
			mission.combat.flash(muzzle); mission.combat.tracer(muzzle,target,Color("eec58d")); infantry_shots+=1
			_sound("res://assets/audio/rifle.wav",muzzle,-29)

func _fire_gun(index:int):
	var gun=guns[index]; var side=int(gun.side); var origin:Vector3=gun.muzzle.global_position
	gun.last=clock
	if side==0: shots_near+=1
	else: shots_far+=1
	var n=shots_near if side==0 else shots_far
	var water=side==1 and n%3==0
	var target=Vector3((-1 if n%2 else 1)*(5.0+float(n%3)*3.0),0,-86-float(n%3)*2 if side==0 else 3+float(n%4)*2)
	if water: target=Vector3(-5 if n%2 else 5,-14.8,-12-float(n%4)*12)
	else: target=_ground(target)
	var projectile=MeshInstance3D.new(); projectile.mesh=SphereMesh.new(); projectile.mesh.radius=.08; projectile.mesh.height=.16; projectile.material_override=_material(Color("ffda82"),true); add_child(projectile)
	projectile.position=origin
	shells.append({"node":projectile,"from":origin,"to":target,"side":side,"age":0.0,"duration":1.7+float(index)*.16,"arc":13.0+index*1.2})
	mission.combat.flash(origin)
	var burst=_particles(origin,14,.40,true,Color(1,.55,.14,.85),.4,1.4,3,7,true)
	var holder=Node3D.new(); add_child(holder); burst.reparent(holder); effects.append({"node":holder,"age":3.5})
	_sound("res://assets/remaster/audio/cannon_fire.wav",origin,-4)

func _impact(point:Vector3,_side:int):
	impacts+=1
	var holder=Node3D.new(); add_child(holder)
	var water=point.y< -10
	var dust=_particles(point,38,2.7,true,Color(.80,.87,.87,.8) if water else Color(.39,.31,.22,.75),.45,3.8,4,9)
	dust.reparent(holder)
	if not water:
		var flash=_particles(point+Vector3.UP*.2,18,.6,true,Color(1,.39,.08,.9),.3,2.2,3,9,true); flash.reparent(holder)
		var light=OmniLight3D.new(); holder.add_child(light); light.position=point+Vector3.UP; light.light_color=Color("ffb55a"); light.omni_range=10; light.light_energy=2.2
		effects.append({"node":holder,"age":0.0,"light":light})
	else: effects.append({"node":holder,"age":0.0})
	_sound("res://assets/remaster/audio/shell_impact.wav",point,-3)
	var distance=point.distance_to(mission.player.position)
	if distance<24: mission.view.shake=maxf(mission.view.shake,.65*(1-distance/24))

func _sound(path:String,point:Vector3,volume:float):
	if not ResourceLoader.exists(path): return
	var player=sounds[sound_index%sounds.size()]; sound_index+=1
	player.position=point; player.stream=load(path); player.volume_db=volume+linear_to_db(maxf(.01,mission.audio.effect_volume)); player.play()

func _cloud_texture()->Texture2D:
	var img=Image.create(64,64,false,Image.FORMAT_RGBA8); var noise=FastNoiseLite.new(); noise.seed=1935; noise.frequency=.12
	for y in 64:
		for x in 64:
			var radius=Vector2(x-31.5,y-31.5).length()/31.5
			var alpha=pow(maxf(0,1-radius),.8)*(.82+noise.get_noise_2d(x,y)*.28)
			img.set_pixel(x,y,Color(1,1,1,alpha))
	return ImageTexture.create_from_image(img)

func _particles(point:Vector3,amount:int,life:float,one_shot:bool,color:Color,scale_min:float,scale_max:float,velocity_min:float,velocity_max:float,glow:=false)->GPUParticles3D:
	var node=GPUParticles3D.new(); add_child(node); node.position=point; node.amount=amount; node.lifetime=life; node.one_shot=one_shot; node.explosiveness=.92 if one_shot else 0.0
	node.visibility_aabb=AABB(Vector3(-20,-8,-20),Vector3(40,40,40))
	var process=ParticleProcessMaterial.new(); process.direction=Vector3.UP; process.spread=55 if one_shot else 19; process.gravity=Vector3(0,-2.5 if one_shot else .25,0)
	process.initial_velocity_min=velocity_min; process.initial_velocity_max=velocity_max; process.scale_min=scale_min; process.scale_max=scale_max
	process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; process.emission_sphere_radius=.35 if one_shot else .8
	var gradient=Gradient.new(); gradient.colors=PackedColorArray([Color(color,0),color,Color(color,.35),Color(color,0)]); gradient.offsets=PackedFloat32Array([0,.12,.65,1])
	var ramp=GradientTexture1D.new(); ramp.gradient=gradient; process.color_ramp=ramp; node.process_material=process
	var mesh=QuadMesh.new(); mesh.size=Vector2.ONE; node.draw_pass_1=mesh
	var material=_material(color,glow); material.albedo_texture=cloud; material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; material.vertex_color_use_as_albedo=true; material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED; material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; material.no_depth_test=false
	mesh.material=material; node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; node.emitting=true
	return node

func _make_far_force(side:int):
	var material=_material(Color("51656b") if side==0 else Color("6c6350"))
	var parts=[]
	for part in 5:
		var mesh
		if part==0: mesh=CapsuleMesh.new(); mesh.radius=.19; mesh.height=.72
		elif part==1: mesh=SphereMesh.new(); mesh.radius=.13; mesh.height=.26
		else: mesh=BoxMesh.new(); mesh.size=Vector3(.12,.52,.14) if part<4 else Vector3(.035,.05,.86)
		var instances=MultiMeshInstance3D.new(); instances.multimesh=MultiMesh.new(); instances.multimesh.transform_format=MultiMesh.TRANSFORM_3D; instances.multimesh.mesh=mesh; instances.multimesh.instance_count=36; instances.material_override=material
		instances.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(instances); parts.append(instances)
		instances.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	far_meshes.append(parts)
	for i in 36:
		var x=(-1 if i%2 else 1)*(16+fmod(float(i)*7.13,35))
		var z=18+fmod(float(i)*6.71,31) if side==0 else -96-fmod(float(i)*6.71,35)
		far_rows.append({"side":side,"index":i,"base":Vector3(x,0,z),"phase":float(i)*1.31})

func _update_far_force():
	for row in far_rows:
		var phase=clock*3.1+row.phase; var p:Vector3=row.base
		p.z+=sin(clock*.16+row.phase)*2.8; p.x+=sin(clock*.12+row.phase)*.6; p=_ground(p)
		var facing_basis=Basis(Vector3.UP,PI if row.side==0 else 0.0)
		for part in 5:
			var local=Vector3(0,1.0,0); var b=facing_basis
			if part==1: local=Vector3(0,1.55,0)
			elif part in [2,3]:
				local=Vector3(-.12 if part==2 else .12,.42,0); b=facing_basis*Basis(Vector3.RIGHT,sin(phase+(PI if part==2 else 0.0))*.35)
			elif part==4: local=Vector3(.25,1.15,.27); b=facing_basis*Basis(Vector3.RIGHT,-.2)
			far_meshes[row.side][part].multimesh.set_instance_transform(row.index,Transform3D(b,p+facing_basis*local+Vector3.UP*(absf(sin(phase))*.025)))

func diagnostics()->Dictionary:
	return {"near_artillery_shots":shots_near,"far_artillery_shots":shots_far,"impacts":impacts,"infantry_shots":infantry_shots,"full_rig_soldiers":soldiers.size(),"far_soldiers":far_rows.size(),"active_shells":shells.size(),"active_effects":effects.size()}
