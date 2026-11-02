extends Node3D
# Forward fighters travel on the side chains before bridge boards are laid.
var mission
var fighters:Array=[]
var rows:Array=[]
var active:=false
var shots:=0
var sacrifice_seen:=false
var response_seen:=false
var response_clock:=0.0
var exposure:=0.0
var site_at_start:=0
var sacrifice_elapsed:=0.0
func setup(m):
	mission=m
	for i in 2:
		var actor=mission._actor("Vanguard_"+str(i),Vector3.ZERO,false)
		actor.set_physics_process(false);actor.collision_layer=0;actor.collision_mask=0;actor.hide()
		fighters.append(actor);rows.append({"life":"advance","fire":float(i)*.7,"time":0.0,"origin":Vector3.ZERO})
func start():
	if active:return
	active=true;shots=0;sacrifice_seen=false;response_seen=false;exposure=0;response_clock=0;sacrifice_elapsed=0
	site_at_start=mission.repair.site
	for i in 2:
		var actor=fighters[i];actor.restore();actor.position=Vector3(1.43 if i==0 else -1.43,0,-13.1 if site_at_start>0 else 1.7+float(i));actor.rotation=Vector3(0,PI,0);actor.reset_physics_interpolation();actor.show()
		rows[i].life="advance";rows[i].time=0;rows[i].fire=float(i)*.7
	mission.say("周班长","突击组沿铁索先上！两岸火力掩护，铺板组跟进！")
func stop():
	active=false
	for actor in fighters:actor.hide();actor.visual.hand_targets=[];actor.visual.speed=0
func tick(delta:float):
	if not active or mission.paused or mission.failed:return
	if response_clock>0:
		response_clock-=delta
		if response_clock<=0 and not response_seen:
			response_seen=true;mission.say("林川","不能辜负同志的牺牲，冲啊！");mission.save_checkpoint()
	var repairing=mission.ledger.current=="repair"
	var site=mission.repair.site if repairing else 1
	for i in 2:
		var actor=fighters[i];var row=rows[i];row.time+=delta
		if row.life=="gone":continue
		if row.life=="hit":
			actor.visual.mode="hit";actor.visual.armed=false;actor.visual.speed=0
			actor.position=Vector3(row.origin)+Vector3(.95*smoothstep(0,.85,row.time),0,0)
			actor.rotation.z=-smoothstep(.2,.9,row.time)*.7
			if row.time>.9:row.life="fall";row.time=0;actor.visual.mode="dead"
			continue
		if row.life=="fall":
			actor.position.y-=minf(18,3+row.time*9.8)*delta;actor.rotation.x+=delta*.7
			if actor.position.y< -14.8:mission.assault._splash(Vector3(actor.position.x,-14.8,actor.position.z));actor.hide();row.life="gone"
			continue
		var goal_z=(-12.6 if site==0 else -32.3)-float(i)*1.15
		if not repairing:goal_z=-51.8-float(i)*.9
		if mission.ledger.current in ["relay","complete"]:goal_z=-84-float(i)*1.2
		var gap=(actor.position.z< -7.3 and actor.position.z> -11.8 and not mission.world.v2_repair_is_enabled(0)) or (actor.position.z< -26.4 and actor.position.z> -31.8 and not mission.world.v2_repair_is_enabled(1))
		var moving=absf(actor.position.z-goal_z)>.12
		if moving:
			actor.position.z=move_toward(actor.position.z,goal_z,delta*(2.0 if gap else 3.7));actor.visual.speed=2.0 if gap else 3.7
			actor.rotation.y=rotate_toward(actor.rotation.y,(PI/2 if i==0 else -PI/2) if gap else PI,delta*4)
			actor.visual.mode="climb" if gap else "run";actor.visual.armed=not gap;row.life="advance"
		else:
			row.life="cover";actor.visual.speed=0;actor.visual.mode="kneel_aim" if i==0 else "aim";actor.visual.armed=true
			actor.rotation.y=rotate_toward(actor.rotation.y,PI,delta*4)
			row.fire-=delta
			if repairing and row.fire<=0:_fire(actor);row.fire=1.3+float(i)*.37
	if repairing and mission.player.carrying and ahead_count()>0:
		mission.assault.cover_time=maxf(mission.assault.cover_time,1.8)
		if not sacrifice_seen and mission.repair.site==0 and mission.player.position.z< -5.8 and rows[0].life=="cover":
			exposure+=delta
			if exposure>1.1:_sacrifice()
func ahead_count()->int:
	var count=0
	for i in 2:
		if rows[i].life in ["cover","advance"] and fighters[i].visible and fighters[i].position.z<mission.player.position.z-1:count+=1
	return count
func frontline_ready(site:int)->bool:
	if not active:return true
	for i in 2:
		if rows[i].life=="cover" and fighters[i].position.z<(-11.8 if site==0 else -31.8):return true
	return false
func _fire(actor):
	var target=Vector3(-1.3 if shots%2 else 1.3,1.3,-80.9)
	var muzzle=actor.visual.muzzle.global_position
	var block=mission.combat.ray(muzzle,target,1)
	mission.combat.flash(muzzle);mission.combat.tracer(muzzle,block.position if not block.is_empty() else target,Color("ffd295"));mission.sound("res://assets/audio/rifle.wav",-27);shots+=1
	for enemy in mission.enemies:
		if not enemy.dead:enemy.suppression=maxf(enemy.suppression,.7)
func _sacrifice():
	var shooter=null
	for enemy in mission.enemies:
		if not enemy.dead:shooter=enemy;break
	if shooter==null:
		for i in mission.battlefield.soldiers.size():
			if mission.battlefield.roles[i].side==1 and not mission.battlefield.soldiers[i].dead:shooter=mission.battlefield.soldiers[i];break
	if shooter==null:return
	var victim=fighters[0];var muzzle=shooter.visual.muzzle.global_position
	mission.combat.flash(muzzle);mission.combat.tracer(muzzle,victim.position+Vector3.UP*1.1,Color("efa272"));mission.sound("res://assets/audio/rifle.wav",-19)
	sacrifice_seen=true;rows[0].life="hit";rows[0].time=0;rows[0].origin=victim.position;victim.visual.hurt()
	sacrifice_elapsed=mission.elapsed;print("VANGUARD_SACRIFICE elapsed=",sacrifice_elapsed," builder=",mission.player.position," cover=",victim.position)
	mission.assault.fallen+=1;mission.assault.wounded+=1
	mission.say("阿木","前面的同志中弹了！压住对岸！");response_clock=2.0;mission.save_checkpoint()
func snapshot()->Dictionary:return {"sacrifice_seen":sacrifice_seen,"response_seen":response_seen}
func restore(data:Dictionary):
	sacrifice_seen=bool(data.get("sacrifice_seen",false));response_seen=bool(data.get("response_seen",sacrifice_seen))
	if sacrifice_seen:fighters[0].hide();rows[0].life="gone"
	if sacrifice_seen and not response_seen:response_clock=1.0
