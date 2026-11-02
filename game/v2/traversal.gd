extends Node3D
signal completed(result:Dictionary)
var mission
var active:=false
var phase:="approach"
var checkpoint:=0
var fixed:=false
var alignment:=-.55
var tension:=0.0
var hold_time:=0.0
var clock:=0.0
var wind_force:=0.0
var warning_zone:=-1
var feedback:=""
var support:MeshInstance3D
var loose_plank:MeshInstance3D
var loose_shape:CollisionShape3D
var rope:MeshInstance3D
var wind_audio:AudioStreamPlayer
var allies_wait:=0.0
const APPROACH=Vector3(1.43,.05,-54.35)
const MIDDLE=Vector3(1.2,.05,-58.2)
const LANDING=Vector3(1.43,.10,-62.35)

func setup(owner_mission):
	mission=owner_mission
	if support: return
	var wood=_material(Color("78644a"))
	var metal=_material(Color("555d5c"))
	support=_box("Middle_safe_support",Vector3(1.5,.18,1.6),Vector3(1.05,-.10,-58.2),wood,true)
	for x in [.35,1.7]: _box("Support_clamp",Vector3(.08,.75,.08),Vector3(x,-.35,-58.2),metal,false)
	loose_plank=_box("Loose_support_plank",Vector3(3.35,.14,1.15),Vector3(0,-.07,-59.1),wood,true)
	loose_shape=loose_plank.get_node("Body/Shape")
	rope=_box("Tension_rope",Vector3(.035,.035,2.0),Vector3(.82,.83,-58.25),_material(Color("c8ad70")),false)
	rope.rotation.x=.05
	wind_audio=AudioStreamPlayer.new(); add_child(wind_audio)
	wind_audio.stream=load("res://assets/remaster/audio/wind.wav")
	wind_audio.volume_db=-35
	wind_audio.finished.connect(func():
		if active and phase in ["climb_a","climb_b"]: wind_audio.play())
	_render()

func start(state:Dictionary={}):
	active=true
	checkpoint=clampi(int(state.get("checkpoint",0)),0,2)
	fixed=bool(state.get("fixed",false))
	phase="rest" if fixed and checkpoint>=1 else ("shelter" if checkpoint>=1 else "approach")
	if checkpoint>=2: phase="done"
	alignment=clampf(float(state.get("alignment",-.55)),-1,1)
	tension=0; hold_time=0; clock=0; warning_zone=-1; wind_force=0
	feedback=""
	mission.player.climbing=false
	mission.player.carrying=false
	mission.player.locked=false
	mission.player.visual.rotation=Vector3.ZERO
	mission.player.visual.mode="idle"
	if state.has("allies"): _restore_allies(state.allies)
	_render()
	if phase=="done": completed.emit({"checkpoint":2,"crisis_fixed":true})

func stop():
	active=false
	if wind_audio: wind_audio.stop()
	if not mission: return
	mission.player.climbing=false
	mission.player.carrying=false
	mission.player.visual.rotation=Vector3.ZERO
	mission.player.visual.hand_targets=[]
	mission.player.visual.mode="idle"
	mission.player.locked=false
	mission.amu.visual.hand_targets=[]
	mission.amu.fixed_pose=""

func interact():
	if not _can_tick(): return
	match phase:
		"approach":
			if mission.player.position.distance_to(APPROACH)<1.7: _grab(false)
			else: feedback="靠近右侧铁索的抓握点。"
		"shelter":
			if mission.player.position.distance_to(MIDDLE)<1.7:
				phase="align"
				mission.player.locked=true
				mission.player.visual.mode="brace"
				mission.amu.walk([Vector3(1.43,0,-54.35),Vector3(1.43,0,-57.6),Vector3(.35,0,-58.05)],2.6)
				mission.amu.chain_from=-54.8; mission.amu.chain_to=-62.2
				allies_wait=0
				mission.say("阿木","我来抓住绳端，你把松板摆正。")
		"rest":
			if mission.player.position.distance_to(MIDDLE)<1.7: _grab(true)

func tick(delta:float):
	if not _can_tick(): return
	clock+=delta
	if phase not in ["climb_a","climb_b"] and wind_audio.playing: wind_audio.stop()
	if phase in ["align","tension"]:
		mission.player.position=mission.player.position.move_toward(Vector3(.95,.05,-58.55),delta*1.7)
		mission.player.rotation.y=.12
		mission.player.visual.mode="brace"
		mission.player.visual.hand_targets=[Vector3(.65,.83,-58.18),Vector3(.95,.83,-58.18)]
		if not mission.amu.moving and mission.amu.position.distance_to(Vector3(.35,0,-58.05))<1:
			mission.amu.fixed_pose="brace"
			mission.amu.face(mission.player.position)
			mission.amu.visual.hand_targets=[Vector3(.50,.83,-58.10),Vector3(.72,.83,-58.10)]
		allies_wait+=delta
		if allies_wait>12 and mission.amu.position.distance_to(MIDDLE)>2:
			feedback="阿木还没到支点；按 Q 重新引导他沿铁索靠近。"
			if Input.is_action_just_pressed("signal"):
				mission.amu.walk([Vector3(1.43,0,-54.35),Vector3(1.43,0,-57.6),Vector3(.35,0,-58.05)],2.6)
				allies_wait=0
	if phase=="align":
		alignment=clampf(alignment+Input.get_axis("move_left","move_right")*delta*.65,-1,1)
		if Input.is_action_just_pressed("jump"):
			if absf(alignment)<=.18:
				alignment=0; phase="tension"; feedback="位置已吸附。按住 E 收紧绳索，进入亮区后空格检查。"
			else: feedback="还没有对齐。用 A / D 调整到中间亮区。"
	elif phase=="tension":
		if Input.is_action_pressed("interact"):
			tension=clampf(tension+delta*.38,0,1)
			hold_time+=delta
		else: tension=maxf(0,tension-delta*.12)
		if Input.is_action_just_pressed("jump"):
			if tension>=.35 and tension<=.85 and hold_time>=1.2:
				if mission.amu.position.distance_to(MIDDLE)<1.8 and not mission.amu.moving: _secure()
				else: feedback="保持绳子，阿木正在靠近支点。"
			else: feedback="绳索太松或太紧。张力留在 35%—85% 之间再检查。"
	_render()

func _grab(second:bool):
	phase="climb_b" if second else "climb_a"
	mission.player.climbing=true
	mission.player.locked=false
	mission.player.carrying=false
	mission.player.climb_progress=0
	mission.player.balance=0
	mission.player.velocity=Vector3.ZERO
	mission.player.movement_velocity=Vector3.ZERO
	mission.player.visual.mode="climb"
	mission.player.visual.hand_targets=[]
	mission.player.rotation.y=PI/2
	warning_zone=-1
	wind_audio.play()
	mission.say("周班长","风有预兆。偏向哪边，就往反方向调。")

func advance_player(delta:float):
	if not _can_tick() or phase not in ["climb_a","climb_b"] or mission.player.locked: return
	# Small integration steps give equivalent wind response under frame spikes.
	var remaining=minf(delta,.25)
	while remaining>0:
		var dt=minf(remaining,1.0/120)
		remaining-=dt
		var player=mission.player
		var forward=-Input.get_axis("move_forward","move_back")
		var second=phase=="climb_b"
		var duration=10.5 if second else 10.0
		player.climb_progress=clampf(player.climb_progress+forward*dt/duration,0,1)
		var p=player.climb_progress
		var strength=.14+.18*smoothstep(.18,.75,p)
		wind_force=sin(p*TAU*(1.12 if second else .80)+(1.1 if second else -.2))*strength
		var correction=Input.get_axis("move_left","move_right")
		var assistance=.76 if player.balance_assist else 1.0
		var wind=wind_force*assistance if absf(forward)>.01 else 0.0
		player.balance=clampf(player.balance+(wind+correction*.66-player.balance*.18)*dt,-1.1,1.1)
		player.position=Vector3(1.43,.04,lerpf(-58.2 if second else -54.5,-62.35 if second else -58.2,p))
		player.visual.rotation.z=player.balance*.20+sin(p*TAU*2)*.025
		player.visual.speed=absf(forward)*1.4
		wind_audio.volume_db=-31+absf(wind_force)*20
		wind_audio.pitch_scale=.85+absf(wind_force)*.6
		var zone=int(floor(p*3))
		if zone!=warning_zone:
			warning_zone=zone
			mission.say("阿木","风将把身体推向右，先向左留一点余量。" if _forecast(p)>0 else "风将把身体推向左，先向右留一点余量。")
		if absf(player.balance)>1.0:
			player.climbing=false
			player.visual.rotation.z=0
			wind_audio.stop()
			player.damage(1000)
			return
		if p>=1:
			player.climbing=false
			player.visual.rotation.z=0
			player.visual.mode="idle"
			player.position.y=.08
			wind_audio.stop()
			if second:
				checkpoint=2; phase="done"; active=false
				completed.emit({"checkpoint":2,"crisis_fixed":true})
			else:
				checkpoint=1; phase="shelter"
				mission.save_checkpoint()
				mission.say("阿木","先停在支点上。前面的松板得重新拉住。")
			return

func _forecast(progress:float)->float:
	return sin(minf(progress+.18,1)*TAU*(1.12 if phase=="climb_b" else .80)+(1.1 if phase=="climb_b" else -.2))

func _secure():
	fixed=true; phase="rest"; checkpoint=1
	mission.player.locked=false
	mission.player.visual.hand_targets=[]
	mission.player.visual.mode="idle"
	mission.amu.visual.hand_targets=[]; mission.amu.fixed_pose=""
	feedback="松板已固定；在支点休息，E 抓住下一段铁索。"
	_render()
	mission.sound("res://assets/audio/wood.wav",-14)
	mission.save_checkpoint()

func status()->Dictionary:
	var objective="沿已修好的桥面，找到右侧抓索点"
	var hint="靠近右侧铁索 · E 抓索"
	var progress=0.0
	var detail=feedback
	var point=APPROACH
	match phase:
		"climb_a", "climb_b":
			objective="铁索之上 · 抵达下一个稳定支点"
			hint="W / S 前后 · A / D 向倾斜反方向调平衡 · 停下可稳住"
			progress=(.5 if phase=="climb_b" else 0.0)+mission.player.climb_progress*.5
			detail="风向预警：%s · 平衡 %+.0f%%"%["推向右 → 向左修正（A）" if _forecast(mission.player.climb_progress)>0 else "推向左 ← 向右修正（D）",mission.player.balance*100]
			point=LANDING if phase=="climb_b" else MIDDLE
		"shelter": objective="安全支点 · 与阿木处理松动桥板"; hint="E 握住支撑绳，开始固定"; progress=.5; point=MIDDLE
		"align": objective="把松动的支撑板摆正"; hint="A / D 调整 · 对齐 ±18% 内按空格确认"; progress=1-absf(alignment); detail="对齐偏差 %+.0f%% · %s"%[alignment*100,feedback]; point=MIDDLE
		"tension": objective="与阿木共同收紧支撑绳"; hint="按住 E 张紧 · 35%—85% 亮区内按空格检查"; progress=tension; detail="绳索张力 %.0f%% · %s"%[tension*100,feedback]; point=MIDDLE
		"rest": objective="松板已经稳住 · 继续通过第二段铁索"; hint="E 抓索 · 中点进度已保存"; progress=.5; point=MIDDLE
		"done": objective="铁索危机解除"; progress=1; point=LANDING
	return {"objective":objective,"hint":hint,"progress":progress,"detail":detail,"waypoint":point}

func safe_position()->Vector3: return LANDING if checkpoint>=2 else (MIDDLE if checkpoint>=1 else APPROACH)
func snapshot()->Dictionary:
	return {"phase":"done" if checkpoint>=2 else ("rest" if fixed else ("shelter" if checkpoint>=1 else "approach")),"checkpoint":checkpoint,"fixed":fixed,"alignment":alignment,"safe_position":[safe_position().x,safe_position().y,safe_position().z],"allies":_allies_snapshot()}
func _can_tick()->bool: return active and not mission.paused and not mission.failed
func _render():
	if not loose_plank: return
	loose_plank.rotation.x=0.0 if fixed else -.24
	loose_plank.rotation.z=0.0 if fixed else alignment*.20
	loose_shape.disabled=not fixed
	rope.scale.x=1.0 if fixed else (.7+clampf(tension,0,1)*.4)
	rope.rotation.x=0 if fixed else -.10+alignment*.08
func _allies_snapshot()->Array:
	var result=[]
	for actor in [mission.amu,mission.zhou]:
		var remaining=actor.route.slice(actor.route_index) if actor.moving else []
		result.append({"position":[actor.position.x,actor.position.y,actor.position.z],"route":remaining.map(func(p):return [p.x,p.y,p.z])})
	return result
func _restore_allies(data:Array):
	for i in mini(data.size(),2):
		var actor=[mission.amu,mission.zhou][i]
		var values=data[i].get("position",[])
		if values.size()==3: actor.position=Vector3(float(values[0]),float(values[1]),float(values[2]))
		var path=[]
		for p in data[i].get("route",[]):
			if p is Array and p.size()==3: path.append(Vector3(float(p[0]),float(p[1]),float(p[2])))
		actor.walk(path,2.6)
func _material(color:Color)->StandardMaterial3D:
	var mat=StandardMaterial3D.new(); mat.albedo_color=color; mat.roughness=.82; return mat
func _box(label:String,size_value:Vector3,pos:Vector3,mat:Material,solid:bool)->MeshInstance3D:
	var mesh=MeshInstance3D.new(); mesh.name=label; mesh.mesh=BoxMesh.new(); mesh.mesh.size=size_value; mesh.material_override=mat; add_child(mesh); mesh.position=pos
	if solid:
		var body=StaticBody3D.new(); body.name="Body"; body.collision_layer=1; mesh.add_child(body)
		var shape=CollisionShape3D.new(); shape.name="Shape"; shape.shape=BoxShape3D.new(); shape.shape.size=size_value; body.add_child(shape)
	return mesh
