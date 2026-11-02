extends Node3D
# A bounded pool of reinforcements. Movement never writes the player's transform.
const ROUTE=[Vector3(0,0,-7.1),Vector3(0,0,-11.8),Vector3(.65,0,-26.65),Vector3(.65,0,-31.3),Vector3(0,0,-53.1),Vector3(1.43,0,-54.35),Vector3(1.43,0,-58.2),Vector3(1.43,0,-62.6),Vector3(0,0,-74.8),Vector3(0,0,-83.8)]
var mission
var active:=false
var pool:Array=[]
var rows:Array[Dictionary]=[]
var clock:=0.0
var spawn_clock:=0.0
var shot_clock:=0.0
var cover_time:=0.0
var passed:=0
var fallen:=0
var wounded:=0
var volleys:=0
var suppressed_volleys:=0
var observed_hits:=0
var casualty_voice_clock:=0.0
var enemy_dead_clocks:Array[float]=[0,0]
var effects:Array=[]
var bridgehead_cleared:=false
func setup(m):
	mission=m
	for i in 8:
		var actor=mission._actor(("Runner_Amu_" if i%2 else "Runner_")+str(i),Vector3.ZERO,false)
		actor.set_physics_process(false); actor.collision_layer=0; actor.collision_mask=0; actor.hide()
		actor.visual.animation_offset+=i*.63
		pool.append(actor); rows.append({"life":"inactive","index":0,"hits":0,"t":0.0,"lane":(-.66 if i%2 else .66)+sin(i*2.1)*.12,"ready":0.0,"fire_clock":i*.27,"pace":3.15+float(i%3)*.19})
func start():
	if active: return
	stop(); active=true; clock=0; spawn_clock=.1; shot_clock=2.4; cover_time=2
	passed=0; fallen=0; wounded=0; volleys=0; suppressed_volleys=0
	casualty_voice_clock=0
	bridgehead_cleared=false
	observed_hits=mission.combat.hit_count; enemy_dead_clocks=[0,0]
	for enemy in mission.enemies:
		enemy.restore(); enemy.show(); enemy.visual.armed=true; enemy.fixed_pose="aim"
	mission.say("周班长","对岸还有火力！铺板的抓紧，拿枪的掩护！")
func stop():
	active=false
	for actor in pool:
		if is_instance_valid(actor): actor.hide(); actor.visual.hand_targets=[]; actor.visual.speed=0
	for row in rows: row.life="inactive"; row.ready=0.0
	for effect in effects:
		if is_instance_valid(effect.node): effect.node.queue_free()
	effects.clear()
func tick(delta:float):
	if not active or mission.paused or mission.failed: return
	clock+=delta; spawn_clock-=delta; shot_clock-=delta; cover_time=maxf(0,cover_time-delta)
	casualty_voice_clock=maxf(0,casualty_voice_clock-delta)
	if mission.combat.hit_count>observed_hits:
		cover_time=10.0; observed_hits=mission.combat.hit_count
	for i in mission.enemies.size():
		var enemy=mission.enemies[i]
		if not enemy.dead:
			enemy.fixed_pose="aim"; enemy.visual.armed=true; enemy.face(mission.player.position)
	if mission.ledger.current in ["relay","modern","complete"] and not bridgehead_cleared:
		bridgehead_cleared=true
		for enemy in mission.enemies:
			enemy.dead=true; enemy.health=0; enemy.collision_layer=0; enemy.fixed_pose="dead"; enemy.visual.mode="dead"; enemy.visual.armed=false
	if spawn_clock<=0:
		_spawn(); spawn_clock=[.85,1.1,1.4,3.3][int(clock)%4]
	if shot_clock<=0:
		_volley(); shot_clock=3.2
	for i in rows.size(): _advance(i,delta)
	for effect in effects.duplicate():
		effect.t+=delta
		if effect.t>1.0: effect.node.queue_free(); effects.erase(effect)
		else: effect.node.scale=Vector3.ONE*(1+effect.t*8); effect.node.transparency=effect.t
func _spawn():
	if mission.repair.active:
		var count=0
		for row in rows:
			if row.life!="inactive":count+=1
		if count>=3:return
	for i in rows.size():
		var row=rows[i]
		if row.life!="inactive" or clock<float(row.ready): continue
		var actor=pool[i]; row.life="run"; row.index=0; row.hits=0; row.t=0.0
		actor.position=Vector3(row.lane,0,2.8); actor.rotation=Vector3(0,PI,0)
		actor.reset_physics_interpolation()
		row.queue_until=0.0; row.cover_until=0.0; row.cover_next=clock+8+float(i)*.7; row.velocity=Vector3.ZERO
		actor.dead=false; actor.visual.mode="walk"; actor.visual.armed=true; actor.visual.hand_targets=[]; actor.show()
		return
func _advance(i:int,delta:float):
	var row=rows[i]; var actor=pool[i]
	if row.life=="inactive": return
	row.t+=delta
	if row.life=="hit":
		actor.visual.armed=false; actor.visual.mode="hit"; actor.visual.speed=0
		actor.position.x=lerpf(float(row.get("hit_start_x",0)),2.25 if row.lane>0 else -2.25,clampf(row.t/.85,0,1))
		actor.rotation.z=sin(minf(1,row.t/.8)*PI*.5)*(.7 if row.lane>0 else -.7)
		if row.t>.85: row.life="fall"; row.t=0.0; actor.visual.mode="dead"
		return
	if row.life=="fall":
		actor.visual.mode="dead"; actor.position.y-=minf(18,2+row.t*9.8)*delta
		actor.position.z-=delta*.6; actor.rotation.x+=delta*.7
		if actor.position.y< -14.8:
			_splash(Vector3(actor.position.x,-14.8,actor.position.z))
			actor.hide(); row.life="inactive"; row.ready=clock+6
		return
	var index=int(row.index)
	var waiting=(index==1 and not mission.world.v2_repair_is_enabled(0)) or (index==3 and not mission.world.v2_repair_is_enabled(1)) or (index in [5,6,7] and not mission.traversal.fixed) or (index==9 and not mission.relay.clear)
	var goal:Vector3=ROUTE[index]
	var climbing=index in [5,6,7] and not waiting
	if index in [0,2,4,8,9]: goal.x=row.lane
	var staging=(index==0 and not mission.world.v2_repair_is_enabled(0)) or (index==2 and not mission.world.v2_repair_is_enabled(1)) or (index==4 and not mission.traversal.fixed) or (index==8 and not mission.relay.clear)
	if staging: goal.z+=float(i/2)*.68
	if waiting:
		# Fan out behind the unsafe section, instead of piling onto one point.
		goal=Vector3(row.lane*(1.05+float(i%3)*.12),0,ROUTE[maxi(0,index-1)].z+float(i/2)*.68)
	var stage_goal=goal
	var blocked=false
	for j in rows.size():
		if j==i or rows[j].life!="run": continue
		var ahead=pool[j].position
		var planar=Vector2(ahead.x-actor.position.x,ahead.z-actor.position.z)
		var gap_lane=index in [1,3,5,6,7] and not waiting
		if ahead.z<actor.position.z and planar.length()<(1.25 if climbing else .83) and absf(planar.x)<(.72 if gap_lane else .48): blocked=true
	var player_delta=mission.player.position-actor.position; player_delta.y=0
	if player_delta.length()<1.35 and not mission.player.carrying and not climbing and index not in [1,3]:
		goal.x=-1.18 if mission.player.position.x>0 else 1.18
	elif player_delta.length()<.68: blocked=true
	if mission.player.carrying:
		var nearest=Geometry3D.get_closest_point_to_segment(actor.position,mission.player.position,mission.amu.position)
		if actor.position.distance_to(nearest)<.83: blocked=true
	if not waiting and not climbing and index not in [1,3] and i%3==1 and actor.position.z< -12 and clock>=float(row.get("cover_next",0)):
		row.cover_until=clock+1.8; row.cover_next=clock+11+float(i)*.7
	var bound_cover=clock<float(row.get("cover_until",0))
	if blocked: row.queue_until=clock+.55
	blocked=blocked or clock<float(row.get("queue_until",0))
	var arrived=actor.position.distance_to(goal)<.13
	if (waiting and arrived) or blocked or bound_cover:
		row.velocity=Vector3.ZERO
		actor.visual.speed=0; actor.visual.mode="kneel_aim" if bound_cover else "aim"; actor.visual.armed=not climbing
		if climbing: actor.visual.mode="climb"
		else:
			var look=Vector3(0,0,-84)-actor.position
			actor.rotation.y=rotate_toward(actor.rotation.y,atan2(look.x,look.z),delta*3.5)
		if not climbing: _squad_fire(i,delta)
		return
	if not waiting and actor.position.distance_to(stage_goal)<.16:
		row.index+=1
		if int(row.index)>=ROUTE.size():
			passed+=1; actor.hide(); row.life="inactive"; row.ready=clock+1.8
		return
	var before=actor.position; var diff=goal-before
	var pace=1.65 if climbing else float(row.pace)
	var velocity:Vector3=row.get("velocity",Vector3.ZERO)
	velocity=velocity.move_toward(diff.normalized()*pace,delta*7)
	var step=velocity*delta
	actor.position=goal if step.length()>diff.length() else before+step
	row.velocity=velocity
	actor.rotation.y=rotate_toward(actor.rotation.y,PI/2 if climbing else atan2(diff.x,diff.z),delta*5)
	actor.visual.speed=actor.position.distance_to(before)/maxf(delta,.001)
	actor.visual.mode="climb" if climbing else "run"
	actor.visual.armed=not climbing
	# Firing is performed from a stable cover stance, not while turning to walk.

func _squad_fire(index:int,delta:float):
	var row=rows[index]; var actor=pool[index]
	row.fire_clock=float(row.fire_clock)-delta
	if float(row.fire_clock)>0 or actor.position.z> -.3: return
	row.fire_clock=1.2+float(index%3)*.37
	var enemy=null
	for target in mission.enemies:
		if not target.dead: enemy=target; break
	if enemy==null: return
	var muzzle=actor.visual.muzzle.global_position
	var end=enemy.position+Vector3(sin(index+clock)*.38,1.15,0)
	var obstruction=mission.combat.ray(muzzle,end,1)
	mission.combat.flash(muzzle); mission.combat.tracer(muzzle,obstruction.position if not obstruction.is_empty() else end,Color("ffd29b"))
	mission.sound("res://assets/audio/rifle.wav",-31)
	if actor.position.z< -12 and obstruction.is_empty(): enemy.suppression=maxf(enemy.suppression,.28)


func _volley():
	var shooter=null
	for enemy in mission.enemies:
		if not enemy.dead and enemy.suppression<=0:
			shooter=enemy; break
	if shooter==null or cover_time>0:
		suppressed_volleys+=1; return
	var victim=-1; var front=INF
	for i in rows.size():
		if rows[i].life=="run" and pool[i].position.z< -.5 and pool[i].position.z> -76 and pool[i].position.z<front:
			victim=i; front=pool[i].position.z
	if victim<0: return
	var actor=pool[victim]
	var origin=shooter.visual.muzzle.global_position
	var target=actor.position+Vector3(0,1.15,0)
	# Harassing fire includes visible misses rather than an inevitable hit.
	var aimed_hit=(volleys+1)%3==0
	if not aimed_hit: target+=Vector3(1.1 if volleys%2 else -1.1,.2,0)
	var obstruction=mission.combat.ray(origin,target,1)
	mission.combat.flash(origin); mission.sound("res://assets/audio/rifle.wav",-24)
	mission.combat.tracer(origin,obstruction.position if not obstruction.is_empty() else target,Color("efaa7a"))
	volleys+=1
	if not obstruction.is_empty() or not aimed_hit: return
	rows[victim].hits+=1; actor.visual.hurt(); wounded+=1
	if int(rows[victim].hits)>=2: _casualty(victim)
	elif casualty_voice_clock<=0:
		mission.say("阿木","有同志中弹！快压住对岸！"); casualty_voice_clock=12
func _casualty(index:int):
	if rows[index].life!="run": return
	rows[index].life="hit"; rows[index].t=0.0; fallen+=1
	rows[index].hit_start_x=pool[index].position.x
	print("[Assault] casualty ",index," at ",pool[index].position," under unsuppressed fire")
	if fallen==1 or casualty_voice_clock<=0:
		mission.say("林川","同志！……掩护，别让后面的人再倒下！"); casualty_voice_clock=15
func _splash(point:Vector3):
	var node=MeshInstance3D.new(); node.mesh=TorusMesh.new(); node.mesh.inner_radius=.22; node.mesh.outer_radius=.27
	var mat=StandardMaterial3D.new(); mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_color=Color(.78,.89,.90,.65); mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	node.material_override=mat; add_child(node); node.position=point; effects.append({"node":node,"t":0.0})
	mission.sound("res://assets/audio/river.wav",-27)
func snapshot()->Dictionary:
	return {"passed":passed,"fallen":fallen,"wounded":wounded,"enemy_health":mission.enemies.map(func(enemy):return enemy.health),"bridgehead_cleared":bridgehead_cleared}
func restore(data:Dictionary):
	passed=maxi(0,int(data.get("passed",0))); fallen=maxi(0,int(data.get("fallen",0))); wounded=maxi(0,int(data.get("wounded",0)))
	bridgehead_cleared=bool(data.get("bridgehead_cleared",false))
	var healths=data.get("enemy_health",[])
	for i in mini(healths.size(),mission.enemies.size()):
		var enemy=mission.enemies[i]; enemy.health=int(healths[i]); enemy.dead=enemy.health<=0
		enemy.collision_layer=0 if enemy.dead else 4; enemy.fixed_pose="dead" if enemy.dead else "aim"; enemy.visual.mode=enemy.fixed_pose; enemy.visual.armed=not enemy.dead
