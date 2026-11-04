extends Node3D
const InputKeys=preload("res://game/golden_hook/input_keys.gd")
const P=preload("res://game/golden_hook/props.gd")
const Model=preload("res://game/golden_hook/fishing_model.gd")
const Fish=preload("res://game/golden_hook/fish.gd")
var mission
var model=Model.new()
var active:=false
var pond:=0
var power:=0.0
var charging:=false
var aim_angle:=0.0
var rod:Node3D
var rod_tip:Node3D
var bobber:Node3D
var line_mesh:MeshInstance3D
var ripple:MeshInstance3D
var hooked_fish:Node3D
var landing:=Vector3.ZERO
var cast_start:=Vector3.ZERO
var clock:=0.0
var camera_saved:Vector3
var camera_pitch:=0.0
var rod_segments:Array=[]
var rod_bend:=0.0
var approaching_fish:Node3D
var splash_clock:=0.0
var back_angle:=-1.5
func _ready():
	model.state_changed.connect(_state_changed)
	model.caught.connect(_caught)
	model.escaped.connect(func(reason): mission.hud.toast(reason,4.5); mission.audio.cue("slip"))
	bobber=Node3D.new(); add_child(bobber)
	P.ellipsoid(bobber,Vector3(.055,.105,.055),Vector3.ZERO,"b4593e")
	P.ellipsoid(bobber,Vector3(.061,.055,.061),Vector3(0,-.045,0),"ded9ba")
	P.cylinder(bobber,Vector3(0,-.1,0),Vector3(0,.12,0),.005,P.mat("574e36"))
	line_mesh=MeshInstance3D.new(); add_child(line_mesh)
	var line_mat=P.mat("c8c4a8"); line_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; line_mesh.material_override=line_mat
	var torus=TorusMesh.new(); torus.inner_radius=.33; torus.outer_radius=.345; torus.rings=32; torus.ring_segments=6
	var ring_mat=P.mat("a2baab",.3); ring_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; ring_mat.albedo_color.a=.3
	ripple=P.mesh(self,torus,Vector3.ZERO,ring_mat)
	hooked_fish=Fish.new(); add_child(hooked_fish)
	approaching_fish=Fish.new();approaching_fish.shadow=true;add_child(approaching_fish);approaching_fish.hide()
	visible=false
func enter(index:int):
	if active: return
	pond=index; active=true; visible=true; power=0; charging=false; aim_angle=0
	mission.player.locked=true; mission.player.visual.reset_pose()
	mission.player.rotation.y=PI/2; mission.player.rotation_direction=PI/2
	mission.view.cinematic=true; camera_saved=mission.view.camera_rotation
	var actor=mission.player.visual
	rod=Node3D.new(); actor.add_child(rod); rod.position=Vector3(-.10,1.08,.32)
	rod_segments=[]
	for i in 16:rod_segments.append(P.cylinder(rod,Vector3(0,0,i*.15),Vector3(0,0,(i+1)*.15),lerpf(.019,.005,i/15.0),P.mat("796747")))
	rod_tip=Node3D.new(); rod.add_child(rod_tip); rod_tip.position=Vector3(0,.29,2.3)
	actor.external_grip=true
	actor.set_contact("rod",rod)
	model.bite_window=mission.reaction_window
	model.prepare()
	mission.audio.set_mood("urgent" if pond==1 else "fishing")
	mission.world.work_hook.reparent(bobber,false); mission.world.work_hook.position=Vector3(0,-.22,0); mission.world.work_hook.rotation=Vector3.ZERO; mission.world.work_hook.scale=Vector3.ONE; mission.world.work_hook.show()
	_camera()
func exit():
	if not active: return
	model.cancel(); active=false; visible=false; charging=false
	mission.world.work_hook.reparent(mission.world,true); mission.world.work_hook.hide()
	if is_instance_valid(rod): rod.queue_free()
	rod=null; mission.player.visual.reset_pose(); mission.player.locked=false
	rod_segments.clear();rod_bend=0
	mission.view.cinematic=false; mission.view.camera_rotation=camera_saved
	mission.view.position=mission.player.position+Vector3(0,1.35,0)
	mission.view.camera.position=Vector3(.38,.12,4.6); mission.view.camera.rotation=Vector3.ZERO
	mission.hud.fishing_panel.hide()
func input(event):
	if not active or mission.paused: return
	if event is InputEventMouseMotion and model.state==Model.State.PREPARE:
		aim_angle=clampf(aim_angle-event.relative.x*.0035,-.72,.72)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and model.state==Model.State.PREPARE:
			charging=true; power=.08
		elif not event.pressed and charging:
			charging=false
			_cast()
	if event is InputEventKey and event.pressed and not event.echo:
		if InputKeys.matches(event,KEY_SPACE): model.strike()
		elif InputKeys.matches(event,KEY_Q): exit()
		elif InputKeys.matches(event,KEY_E) and model.state in [Model.State.ESCAPED,Model.State.CAUGHT]:
			if mission.story.step in ["first_fishing","last_fishing"]: power=0; model.prepare()
			else: exit()
func _cast():
	cast_start=rod_tip.global_position
	back_angle=rod.rotation.x
	var direction=Vector3.RIGHT.rotated(Vector3.UP,aim_angle)
	landing=mission.player.position+direction*(1.8+power*6.2); landing.y=-.14
	model.cast(power,mission.world.valid_water(landing,pond))
	mission.audio.cue("cast")
func tick(delta):
	if not active: return
	clock+=delta
	if charging: power=clampf(power+delta*.65,.08,1)
	model.tick(delta,Input.is_action_pressed("shoot"))
	var s=model.state
	var rod_angle=-1.28-power*.60 if charging else (-.86 if s in [Model.State.HOOKED,Model.State.CAUGHT] else -.13)
	if s==Model.State.CASTING:rod_angle=lerp_angle(back_angle,-.12,smoothstep(0,.42,model.clock))
	if s==Model.State.REELING: rod_angle=-.12-model.tension*.26+sin(clock*4)*.025
	rod.rotation.x=lerp_angle(rod.rotation.x,rod_angle,minf(delta*8,1))
	rod.rotation.y=aim_angle
	rod.position.y=1.08+(sin(clock*5)*.013 if s==Model.State.REELING else 0.0)
	var desired_bend=(.04+pow(model.tension,2)*.46)*(1.15 if pond==1 else 1.0) if s in [Model.State.REELING,Model.State.HOOKED] else (.06*model.nibble() if s==Model.State.WAITING else 0.0)
	rod_bend=lerpf(rod_bend,desired_bend,1-exp(-delta*7))
	rod.set_meta("reel_stroke",sin(clock*5)*.045 if s==Model.State.REELING and Input.is_action_pressed("shoot") else 0.0)
	_bend_rod()
	var actor=mission.player.visual
	actor.mode="idle"; actor.speed=0
	actor.hand_targets=actor.contact.targets("rod",rod)
	var fishing=s in [Model.State.CASTING,Model.State.WAITING,Model.State.BITE,Model.State.HOOKED,Model.State.REELING,Model.State.CAUGHT]
	bobber.visible=fishing; line_mesh.visible=fishing; ripple.visible=s in [Model.State.WAITING,Model.State.BITE,Model.State.REELING]
	hooked_fish.visible=s in [Model.State.HOOKED,Model.State.REELING,Model.State.CAUGHT]
	approaching_fish.visible=s in [Model.State.WAITING,Model.State.BITE]
	if approaching_fish.visible:
		var approach=clampf(model.clock/maxf(model.wait_duration,.1),0,1) if s==Model.State.WAITING else 1.0
		approaching_fish.global_position=landing+Vector3(cos(clock*1.5)*(1-approach)*1.5,-.17,sin(clock*1.5)*(1-approach)*1.3)
		approaching_fish.rotation.y=-clock*1.5;approaching_fish.speed=1.4
	if s==Model.State.CASTING:
		var t=clampf(model.clock/.65,0,1)
		bobber.global_position=cast_start.lerp(landing,t)+Vector3(0,sin(t*PI)*1.3,0)
	elif s in [Model.State.WAITING,Model.State.BITE]:
		bobber.global_position=landing+Vector3(sin(clock*9)*model.nibble()*.025,-.20 if s==Model.State.BITE else sin(clock*3)*.012,0)
		bobber.rotation.z=sin(clock*12)*model.nibble()*.15
	elif s in [Model.State.REELING,Model.State.HOOKED]:
		var near=mission.player.position+Vector3(2.1,-mission.player.position.y-.14,0)
		var struggle=(.10+model.tension*.12)*(1.35 if pond==1 else 1.0)
		bobber.global_position=landing.lerp(near,model.progress)+Vector3(sin(clock*2.2)*struggle*.4,-.03,cos(clock*3)*struggle)
		hooked_fish.global_position=bobber.global_position+Vector3(0,-.12,0); hooked_fish.rotation.y=PI/2+sin(clock*7)*.23
		hooked_fish.speed=2.8 if pond==1 else 2.0
		splash_clock+=delta
		if splash_clock>1.35:splash_clock=0;mission.world.splash(bobber.global_position)
	elif s==Model.State.CAUGHT:
		var t=clampf(model.clock,0,1)
		# caught state's rules clock is stable; use the view's catch animation clock.
		t=clampf(catch_animation/1.3,0,1)
		hooked_fish.global_position=catch_from.lerp(actor.to_global(Vector3(-.1,1.15,.45)),t)+Vector3(0,sin(t*PI)*.6,0)
		hooked_fish.rotation.y+=delta*4;hooked_fish.speed=3.5
		bobber.global_position=hooked_fish.global_position+Vector3(0,.15,0)
		catch_animation+=delta
		if catch_animation>2:
			exit(); mission.after_fishing(); return
	if ripple.visible:
		ripple.global_position=Vector3(bobber.global_position.x,-.145,bobber.global_position.z)
		var radius=.8+fmod(clock*1.2,1.0)*1.6; ripple.scale=Vector3(radius,1,radius)
	if hooked_fish.visible:
		# The curve's tip is at the actual fish mouth throughout the struggle
		# and lift, rather than floating underneath its centre of mass.
		mission.world.work_hook.global_rotation=Vector3.ZERO
		mission.world.work_hook.global_position=hooked_fish.to_global(Vector3(0,-.004,.147))-Vector3(.023,.027,0)
	if fishing: _line()
	_camera()
	mission.hud.show_fishing(self)
var catch_animation:=0.0
var catch_from:=Vector3.ZERO
func _rod_point(t:float)->Vector3:
	return Vector3(0,.29*t-rod_bend*pow(smoothstep(.2,1,t),2),-.22+2.52*t)
func _bend_rod():
	for i in rod_segments.size():
		var a=_rod_point(i/16.0);var b=_rod_point((i+1)/16.0);var segment=rod_segments[i]
		segment.position=(a+b)*.5;segment.mesh.height=a.distance_to(b);segment.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	rod_tip.position=_rod_point(1.0)
func _line():
	var im=ImmediateMesh.new(); im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var start=rod_tip.global_position; var finish=bobber.global_position
	for i in 25:
		var t=i/24.0; var p=start.lerp(finish,t)
		p.y-=sin(t*PI)*(lerpf(.28,.012,model.tension) if model.state==Model.State.REELING else .18)
		im.surface_add_vertex(to_local(p))
	if hooked_fish.visible:im.surface_add_vertex(to_local(mission.world.work_hook.to_global(Vector3(0,.058,0))))
	im.surface_end(); line_mesh.mesh=im
func _camera():
	var p=mission.player.position
	var caught=model.state==Model.State.CAUGHT
	mission.view.camera.global_position=p+(Vector3(-1.65,1.75,2.7) if caught else (Vector3(-2.8,2.25,3.7) if pond==1 else Vector3(-3.1,2.5,4.3)))
	mission.view.camera.look_at(p+(Vector3(.65,1.05,.3) if caught else Vector3(3.7,.35,-.3)),Vector3.UP)
	mission.view.camera.fov=51 if caught else (55 if pond==1 else 58)
func _state_changed(value):
	if value==Model.State.PREPARE and mission.world.work_hook.get_parent()==bobber:mission.world.work_hook.position=Vector3(0,-.22,0);mission.world.work_hook.rotation=Vector3.ZERO
	elif value==Model.State.WAITING:
		mission.world.splash(landing); mission.audio.cue("splash")
	elif value==Model.State.BITE: mission.audio.cue("bite");mission.world.splash(landing)
	elif value==Model.State.HOOKED: mission.audio.cue("pull")
func _caught():
	catch_animation=0; catch_from=bobber.global_position
	mission.world.splash(catch_from); mission.audio.cue("splash")
	if mission.story.add_fish():
		mission.save_checkpoint()
		mission.hud.toast("小鱼已放入随身鱼篓 · %d 条"%mission.story.inventory.fish,3)
