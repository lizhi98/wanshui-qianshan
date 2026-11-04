extends "res://game/snow/campaign.gd"
const Props=preload("res://game/memorial/props.gd")
const END_INDEX=12
var director
var quiet_walk:=0.0
var quiet_walk_peak:=0.0
var quiet_walk_total:=0.0
var extras:Array=[]
var quartermaster
var young
var veteran
var giver
var crowd
var stock:=3
var parcel:Node3D
var action:=""
var action_clock:=0.0
var action_target:=""
var action_beat:=0
var act_clock:=0.0
var built:=false
var interact_held:=false
var reveal_music_silence:=0.0
var stage_history:Array=[]
func _player_type():return load("res://game/memorial/player.gd")
func sound(path:String,volume:=-12.0):
	# Foot plants own snow audio. Suppress the inherited generic landing/step tap.
	if path=="res://sounds/land.ogg":return
	super.sound(path,volume)
func _world_type():return load("res://game/memorial/world.gd")
func _hud_type():return load("res://game/memorial/hud.gd")
func _audio_type():return load("res://game/memorial/audio.gd")
func _npc_type():return load("res://game/memorial/npc.gd")
func _visual_type():return load("res://game/memorial/visual.gd")
func _weather_type():return load("res://game/memorial/weather.gd")
func _ready():
	super._ready()
	save_store=load("res://game/memorial/save_store.gd").new()
	for e in [["QuartermasterZhou",Vector3(-8,0,40)],["YoungAmu",Vector3(5,0,35)],["VeteranZhou",Vector3(9,0,30)],["Donor",Vector3(-8,0,27)]]:
		var p:Vector3=e[1];p.y=world.height_at(p)+.1;extras.append(_actor(e[0],p,false))
	quartermaster=extras[0];young=extras[1];veteran=extras[2];giver=extras[3]
	for e in [[quartermaster,"老战士"],[young,"小田"],[veteran,"老赵"],[giver,"许成"]]:
		var label=Label3D.new();e[0].add_child(label);label.text=e[1];label.font=load("res://assets/remaster/fonts/NotoSansSC.ttf");label.font_size=28;label.pixel_size=.0028;label.position.y=1.95;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=Color(.85,.83,.73,.78);label.visibility_range_end=8;label.name="CampName"
	for i in actors().size():actors()[i].follow_distance=2.7+i*1.1;actors()[i].pace=.94+float(i%5)*.025
	quartermaster.follow_distance=-8
	observation=load("res://game/memorial/observation.gd").new();observation.setup(self)
	crowd=load("res://game/memorial/crowd.gd").new();add_child(crowd);crowd.setup(self)
	parcel=Props.bundle(player.visual);parcel.position=Vector3(0,1.04,.35);parcel.hide()
	director=load("res://game/memorial/climax.gd").new();add_child(director);director.setup(self)
	built=true;DisplayServer.window_set_title("万水千山 V4.1.5 · 丰碑·雪线之上");main_menu()
	if "--memorial-replay" in OS.get_cmdline_user_args():call_deferred("_start_memorial_replay")
	if "--animation-lab" in OS.get_cmdline_user_args():call_deferred("_start_animation_lab")
	if "--role-audio-lab" in OS.get_cmdline_user_args():call_deferred("_start_role_audio_lab")
	if "--smoke-memorial" in OS.get_cmdline_user_args():call_deferred("_smoke_memorial")
func actors()->Array:return [amu,zhou]+marchers+extras
func actor_by_name(who:String):
	if director and who=="指挥员":return director.commander
	if director and who=="警卫员":return director.guard
	return {"林川":player,"阿木":amu,"周班长":zhou,"老战士":quartermaster,"小田":young,"老赵":veteran,"许成":giver}.get(who)
func main_menu():
	if not built:return
	started=false;paused=false;failed=false;outro_active=false;camera_observing=false;player.locked=true
	audio.clear_voice();action=""
	for a in actors():a.moving=false
	_use_cinematic_camera();view.camera.global_position=Vector3(-20,16,57);view.camera.look_at(Vector3(0,4,23));hud.center_title.text=""
	var actions=[]
	if save_store.exists():actions.append(["继续行军",continue_story])
	actions.append_array([["开始 · 丰碑·雪线之上",begin],["操作与画质",settings_menu],["章节选择",chapter_menu],["退出",quit_game]])
	hud.show_menu("丰碑 · 雪线之上","1935年6月，夹金山。\n最后一批御寒衣物，正等着送到需要它的人手里。\n\nWASD 移动 · 鼠标转向 · Shift 奔跑 · 空格跳跃\nF 观察 · E 取物/交接/查看 · Q 发信号\n\n文学主题取自李本深《丰碑》，人物与地点情节为文学化改编。",actions)
func begin():
	audio.clear_voice();flags.clear();stats={"jumps":0,"signals":0,"clues":0,"walked_m":0.0,"delivered":0};stock=3;elapsed=0;retries=0;act_clock=0;action="";action_clock=0;outro_active=false;outro_clock=0;stage_history=[];observation.reset();weather.clock=0;weather.shelter_visits.clear();crowd.restore_clock(0)
	quiet_walk=0;quiet_walk_peak=0;quiet_walk_total=0
	director.reset()
	stage="CAMP";phase=Phase.INTRO;started=true;paused=false;failed=false;player.restore(Vector3(0,.1,44));player.locked=true;player.carrying=false;parcel.hide();player.visual.pose("");world.reset_parcels(3)
	var spawns=[Vector3(-1,0,39),Vector3(1,0,40),Vector3(3,0,44),Vector3(-3,0,43),Vector3(-8,0,40),Vector3(5,0,35),Vector3(9,0,30),Vector3(-8,0,27)]
	for i in actors().size():
		var a=actors()[i];a.restore();a.position=spawns[i]+Vector3.UP*.1;a.vertical_speed=0;a.pose_name="";a.visual.pose("");a.visual.set_coat(false);a.reset_physics_interpolation()
	young.pose_name="shiver";veteran.pose_name="pack";giver.visual.set_coat(true)
	world.reset_obstacle();world._footprints().clear_dynamic();previous_position=player.position;safe_point=player.position;hud.hide_menu();hud.center_title.text="1935年6月，夹金山。";_use_cinematic_camera();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;save_checkpoint()
func _process(delta):
	var now=Input.is_action_pressed("interact");var interact_press=now and not interact_held;interact_held=now
	var f=Input.is_action_pressed("observe");var q=Input.is_action_pressed("signal");var fp=f and not observe_held;var qp=q and not signal_held;observe_held=f;signal_held=q
	if Input.is_action_just_pressed("pause") and started:toggle_pause()
	if not started or paused or failed or stage=="COMPLETE":return
	elapsed+=delta;act_clock+=delta;director.update(delta)
	if stage=="CAMP" and not flags.get("intro_done",false):
		_cinematic(Vector3(0,2,31),Vector3(-18,14,54).lerp(Vector3(-8,6,48),clampf(act_clock/10,0,1)),delta)
		if act_clock>10:flags.intro_done=true;player.locked=false;hud.center_title.text="";_reset_camera();say("周班长","先别急着上山，帮着把最后几包棉衣送过去。")
		return
	if outro_active:_memorial_outro(delta);return
	if action!="":_action_tick(delta);return
	if fp:camera_observing=not camera_observing
	observation.tick(delta)
	if interact_press:interact()
	if qp:signal_party()
func _physics_process(delta):
	if not built or not started or failed:return
	weather.tick(delta)
	if paused:return
	world.tick(delta)
	for a in extras:a.get_node("CampName").visible=stage=="CAMP"
	var d=player.position.distance_to(previous_position)
	if d<2:stats.walked_m+=d
	previous_position=player.position
	if d>.01 and action=="" and not audio.voice_busy and not camera_observing:
		quiet_walk+=delta;quiet_walk_total+=delta;quiet_walk_peak=maxf(quiet_walk_peak,quiet_walk)
	else:quiet_walk=0
	if outro_active or stage=="COMPLETE":return
	if quartermaster.moving==false and flags.get("march_started",false) and quartermaster.position.distance_to(world.MEMORIAL)<1.2:quartermaster.pose_name="seated"
	if stage=="MARCH" and flags.get("obstacle_cleared",false) and world.route.nearest(player.position).s>world.route.lengths[6]-2:
		_enter("STORM");say("阿木","风上来了！说话都听不清了！");say("周班长","靠岩石避一避。前面看稳了，再招呼后面的同志。")
	if stage=="MARCH" and not flags.get("march_exchange",false) and world.route.nearest(player.position).s>world.route.lengths[3]:flags.march_exchange=true;say("老赵","脚下慢点。我这边腾出手了，你跟着我走。")
	if stage=="MARCH" and not flags.get("obstruction_notice",false) and world.route.nearest(player.position).s>world.route.lengths[3]+8:flags.obstruction_notice=true;say("周班长","前面的枝石压住路了。别挤，先把路让出来。")
	if stage=="STORM" and not flags.get("warm_callback",false) and world.route.nearest(player.position).s>world.route.lengths[8]-2:flags.warm_callback=true;say("小田","刚才分到的棉衣真顶用。要不然这山上可难熬。")
	if stage=="STORM" and flags.get("storm_signal",false) and world.route.nearest(player.position).s>world.route.lengths[15]-2:
		_start_action("count", "",15)
	if stage=="SEARCH":
		if player.position.distance_to(world.MEMORIAL)<16 and flags.get("strap_found",false):_enter("DISCOVERY")
	if stage=="DISCOVERY" and flags.get("ledger_found",false) and _honor_gathered() and director.ready_for_core() and action=="" and not audio.voice_busy and audio.voice_queue.is_empty() and audio.voice_wait<=0:_start_action("reveal","",0)
	if stage=="CONTINUE" and player.position.distance_to(world.route.POINTS[END_INDEX])<4:
		flags.at_pass=true;player.locked=true
		if _memorial_gathered():outro_active=true;outro_clock=0;outro_lines=0;_use_cinematic_camera()
func can_observe(id:String)->bool:
	return {"stock":stage=="CAMP" and not flags.get("stock_seen",false),"wind_mark":stage=="STORM" and not flags.get("wind_seen",false),"strap":stage=="SEARCH" and not flags.get("strap_found",false),"coat":stage=="DISCOVERY" and flags.get("inspected",false) and not flags.get("coat_seen",false),"ledger":stage=="DISCOVERY" and flags.get("coat_seen",false) and not flags.get("ledger_found",false)}.get(id,false)
func clue_found(id:String):
	stats.clues+=1
	print("MEM_CLUE ",id," elapsed=",elapsed)
	match id:
		"stock":flags.stock_seen=true;say("林川","只剩三包了。先看看谁还没领到。")
		"wind_mark":flags.wind_seen=true
		"strap":flags.strap_found=true;say("林川","这根扎带……是他挎包上的。")
		"coat":flags.coat_seen=true;say("林川","这衣服，已经湿透了。")
		"ledger":flags.ledger_found=true;say("林川","挎包还扣着。是山下那本记录。")
	save_checkpoint()
func interact():
	if action!="" or not started or failed:return
	if stage=="CAMP":
		if not player.carrying and stock>0 and player.position.distance_to(world.CRATE)<2.8 and flags.get("stock_seen",false):_start_action("take","",2.5);return
		if player.carrying:
			for entry in [[young,"young"],[veteran,"veteran"],[giver,"giver"],[amu,"amu"]]:
				if entry[0].position.distance_to(player.position)<2.6 and not flags.get("gave_"+entry[1],false):
					if entry[1]=="amu" and not flags.get("gave_giver",false):continue
					_start_action("give",entry[1],4.8);return
		if stats.delivered==3 and player.position.distance_to(quartermaster.position)<2.8:_start_action("old_talk","",19)
	elif stage=="MARCH" and not flags.get("obstacle_cleared",false) and player.position.distance_to(world.route.at(world.route.lengths[4]-3))<3.8:_start_action("clear","",6)
	elif stage=="DISCOVERY" and not flags.get("inspected",false) and player.position.distance_to(quartermaster.position)<2.8:_start_action("inspect","",8)
	elif stage=="SALUTE":_start_action("salute","",9.2)
func signal_party():
	if stage=="STORM" and flags.get("wind_seen",false) and player.position.distance_to(world.route.POINTS[9])<4 and not flags.get("storm_signal",false):
		flags.storm_signal=true;stats.signals+=1;say("林川","这边背风，沿脚印过来！一个一个走！");_group_walk(7,16);save_checkpoint()
func _enter(next:String):
	stage=next;act_clock=0;camera_observing=false;safe_point=player.position+Vector3.UP*.08;stage_history.append({"stage":stage,"time":elapsed});save_checkpoint();print("MEMORIAL_STAGE ",stage," elapsed=",elapsed)
func _group_walk(first:int,last:int):
	for i in actors().size():
		var a=actors()[i]
		if a==quartermaster:continue
		a.pose_name="";var points=[]
		if a.moving:
			for j in range(a.route_index,a.route.size()):points.append(a.route[j])
		var start=first
		if stage=="CONTINUE" and a!=zhou and world.route.nearest(a.position).s>world.route.lengths[14]:start=int(world.route.nearest(a.position).index)+1
		elif first==1:points.append(Vector3(.5,0,36))
		else:points.append(_march_waypoint(first-1))
		points.append_array(_party_path(start,last,i));a.walk(points,2.65+float(i%3)*.08)
func _party_path(first:int,last:int,index:int)->Array:
	var points=[]
	for i in range(first,last+1):
		var p=_march_waypoint(i)
		if i==last:p+=Vector3((index%2)*.8-.4,0,float(index/2)*.65)
		if i==last and last==END_INDEX and stage=="CONTINUE":p=world.route.POINTS[last]+Vector3((index%2)*1.1-.55,0,float(index/2)*1.1+1.0)
		p.y=world.height_at(p)
		points.append(p)
	return points
func _march_waypoint(i:int)->Vector3:
	var p=world.route.POINTS[i]
	var before=world.route.POINTS[maxi(0,i-1)];var after=world.route.POINTS[mini(world.route.POINTS.size()-1,i+1)]
	var incoming=p-before;incoming.y=0;var outgoing=after-p;outgoing.y=0
	if incoming.length()<.01:incoming=outgoing
	if outgoing.length()<.01:outgoing=incoming
	var n1=incoming.normalized().cross(Vector3.UP);var n2=outgoing.normalized().cross(Vector3.UP);var miter=(n1+n2).normalized()
	if miter.length()<.1:miter=n2
	p+=miter*minf(1.0,.48/maxf(.25,miter.dot(n2)));p.y=world.height_at(p)
	return p
var action_duration:=0.0
func _start_action(kind:String,target:String,duration:float):
	if action!="":return
	action=kind;action_target=target;action_duration=duration;action_clock=0;action_beat=0;camera_observing=false;player.locked=true
	safe_point=player.position+Vector3.UP*.08
	var pose=kind if kind in ["take","clear","inspect","salute"] else ("handover" if kind=="give" else "")
	player.visual.pose(pose);player.visual.mode="pickup" if kind in ["take","clear","inspect"] else "idle"
	if kind=="give":
		var recipient=_recipient(target);recipient.pose_name="handover";recipient.visual.pose("handover");_face(player,recipient.position);_face(recipient,player.position)
	if kind=="inspect":_face(player,quartermaster.position)
	if kind=="reveal":_face(player,quartermaster.position);director.start()
	if kind in ["old_talk","count","inspect","reveal","salute"]:_use_cinematic_camera()
	if kind=="salute":
		director.music_cut=false
		for a in actors():
			if a!=quartermaster:a.moving=false;a.pose_name="salute";a.visual.pose("salute");_face(a,quartermaster.position)
func _recipient(id:String):return {"young":young,"veteran":veteran,"giver":giver,"amu":amu}.get(id)
func _face(actor,point:Vector3):
	if actor.has_method("request_facing"):actor.request_facing(point)
	else:
		var d=point-actor.position;actor.rotation.y=lerp_angle(actor.rotation.y,atan2(d.x,d.z),.18)
func _action_tick(delta):
	if action=="reveal":director.tick(delta);return
	action_clock+=delta
	var lines=[]
	match action:
		"give":
			var a=_recipient(action_target);_face(a,player.position);_face(player,a.position)
			var from=player.to_global(Vector3(0,1.05,.40));var to=a.to_global(Vector3(0,1.10,.40))
			parcel.global_position=from.lerp(to,smoothstep(1,2.6,action_clock)) if action_target!="giver" else from
			lines=[[.3,{"young":"小田","veteran":"老赵","giver":"许成","amu":"阿木"}[action_target],{"young":"手都冻僵了……谢谢，你也把领口扣上。","veteran":"搁在我背包上吧。我先替他把绑腿系好。","giver":"我这件还挡风。把这包送给后面那位同志吧。","amu":"我这一路都没暖过来。多谢，回头替我谢他。"}[action_target]]]
		"old_talk":
			lines=[[.2,"老战士","发下去了？"],[3,"林川","这三包都送到了。可后面还有人没领到。"],[7,"老战士","先顾着他们吧。山上风大，把包裹扎紧。"],[12,"林川","您也穿厚一点。"],[15,"老战士","我再查一遍，就跟上。"]]
			_face(quartermaster,player.position);_face(player,quartermaster.position);_cinematic((player.position+quartermaster.position)*.5+Vector3.UP*1.25,quartermaster.position+Vector3(-3,2.0,-2.5),delta)
		"clear":lines=[[.1,"林川","我来搬开这边的石头。后面先等等。"]]
		"count":
			lines=[[.1,"周班长","先在这儿歇口气，我点一下人。"],[4,"周班长","那个管物资的老同志，谁看见了？"],[8,"小田","刚才还在后面，说要看看落下的包裹。"],[12,"林川","我沿来路找。您照看队伍。"]]
			_cinematic(player.position+Vector3(0,1.1,0),player.position+Vector3(4,3.6,4),delta)
		"inspect":
			_face(player,quartermaster.position)
			lines=[[1,"林川","老同志？我们在上面等您。"],[5,"林川","您听见了吗……"]]
			director.shot("检查",quartermaster.position+Vector3(0,.55,0),[quartermaster.position+Vector3(2.4,1.05,.8),quartermaster.position+Vector3(2.5,1.1,-.5),quartermaster.position+Vector3(-2.5,1.15,-.3)],delta)
		"reveal":
			lines=[[.5,"林川","他的棉衣呢？"],[4.5,"周班长","最后那批棉衣……是他安排送出去的。"],[11,"林川","可他自己……"],[15,"周班长","他是军需处长。发给大家的，都记在这儿了。"]]
			if action_clock>15:flags.identity_revealed=true
			if action_clock>25 and action_clock<32:reveal_music_silence+=delta
			_face(zhou,quartermaster.position)
			_cinematic(quartermaster.position+Vector3(0,.75,0),quartermaster.position+Vector3(3.6,1.5,-1.2),delta)
		"salute":
			director.salute_tick(delta)
			_cinematic((quartermaster.position+player.position)*.5+Vector3(0,.85,0),quartermaster.position+Vector3(5,2.8,4.5),delta)
	while action_beat<lines.size() and action_clock>=lines[action_beat][0]:
		say(lines[action_beat][1],lines[action_beat][2]);action_beat+=1
	if action_clock>=action_duration:_finish_action()
func _finish_action():
	var finished=action;action="";player.visual.pose("");player.locked=false
	match finished:
		"take":stock-=1;player.carrying=true;parcel.show();parcel.position=Vector3(0,1.04,.35);world.reset_parcels(stock)
		"give":
			var a=_recipient(action_target);a.pose_name="";a.visual.pose("");flags["gave_"+action_target]=true
			if action_target=="giver":say("林川","好，我替你送过去。")
			else:a.visual.set_coat(true);player.carrying=false;parcel.hide();stats.delivered+=1
			parcel.position=Vector3(0,1.04,.35)
		"old_talk":
			flags.march_started=true;_enter("MARCH");_group_walk(1,6)
			var points=[Vector3(.5,0,36)];points.append_array(_party_path(1,11,4));points.append(world.MEMORIAL);quartermaster.walk(points,2.9);quartermaster.pose_name=""
			say("阿木","前面拐过弯，还有好长一队人。")
		"clear":flags.obstacle_cleared=true;world.clear_obstacle();say("周班长","好了，顺着踩实的地方走。")
		"count":
			_enter("SEARCH");say("周班长","别一个人走远，我随后过来。")
			var index=0
			for companion in actors():
				if companion==quartermaster:continue
				var points=[]
				var here=int(world.route.nearest(companion.position).index)
				if here<11:
					for j in range(here+1,12):points.append(world.route.POINTS[j])
				else:
					for j in range(here,10,-1):points.append(world.route.POINTS[j])
				var offsets=[Vector3(-2.6,0,-1.5),Vector3(-1.8,0,-2.5),Vector3(-.9,0,-3),Vector3(0,0,-3.2),Vector3(.9,0,-3),Vector3(1.8,0,-2.5),Vector3(2.6,0,-1.5)]
				var spot=world.MEMORIAL+offsets[index]
				spot.y=world.height_at(spot);points.append(world.MEMORIAL+Vector3(offsets[index].x*.7,0,-2.2));points.append(spot);companion.set_meta("scene_slot",spot);companion.walk(points,2.9);index+=1

		"inspect":flags.inspected=true
		"reveal":flags.identity_revealed=true;_enter("SALUTE");player.locked=true
		"salute":
			flags.honored=true;_enter("CONTINUE");_group_walk(12,END_INDEX);director.depart();say("阿木","走吧，前面的同志还等着我们。");say("林川","嗯。继续走。")
	if finished in ["old_talk","count","inspect","reveal","salute"]:_reset_camera()
	safe_point=player.position+Vector3.UP*.08;save_checkpoint()
# Scripted shots move on render frames. Free follow moves on physics ticks,
# so interpolate it together with the player and discard history after a cut.
func _use_cinematic_camera():
	view.cinematic = true
	if view.physics_interpolation_mode != Node.PHYSICS_INTERPOLATION_MODE_OFF:
		view.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func _reset_camera():
	super._reset_camera()
	view.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	view.reset_physics_interpolation()

func _cinematic(focus:Vector3,eye:Vector3,delta:float):
	_use_cinematic_camera()
	var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(focus,eye,1))
	if not hit.is_empty():eye=hit.position+(focus-hit.position).normalized()*.3
	view.camera.global_position=view.camera.global_position.lerp(eye,1-exp(-delta*2.8));view.camera.look_at(focus)
func _memorial_gathered()->bool:
	if director.marching and director.phase>=0:
		for a in [director.commander,director.guard]:
			if a.moving or a.position.distance_to(world.route.POINTS[END_INDEX])>5:return false
	for a in actors():
		if a==quartermaster:continue
		if a.moving or a.position.distance_to(world.route.POINTS[END_INDEX])>5:return false
	return true
func _memorial_outro(delta):
	outro_clock+=delta;var t=clampf(outro_clock/28,0,1);var base=world.route.POINTS[END_INDEX]
	_cinematic(base+Vector3(0,1.2,0),base+Vector3(8+t*6,8+t*18,10+t*18),delta)
	if outro_clock>7:hud.center_title.text="《丰碑·雪线之上》"
	if outro_clock>14:hud.center_title.text="有些身影停在了风雪中，\n他们守护的队伍仍在前行。"
	if outro_clock>18:hud.center_title.text="以李本深文学作品《丰碑》为创作基底，结合1935年红军翻越夹金山的历史背景，通过互动叙事再现军需处长舍己为人、无私奉献的感人故事。"
	if outro_clock>28:hud.center_title.text="谨以此作，致敬军需处长胡军（1889—1935）以及长征途中牺牲的红军将士。"
	if outro_clock>39:finish_level()
func finish_level():
	if stage!="CONTINUE" or not flags.get("honored",false) or not flags.get("at_pass",false) or not _memorial_gathered():return
	stage="COMPLETE";flags.complete=true;outro_active=false;safe_point=player.position;save_checkpoint();_settlement()
func _settlement():
	paused=true;player.locked=true;hud.center_title.text=""
	hud.show_menu("丰碑 · 雪线之上","第二关完成。\n\n你送出的棉衣，仍穿在继续前进的同志身上。\n你记住了山脚见过的那个人。\n队伍继续向前。\n\n文学主题取自李本深《丰碑》。\n人物、对白及具体地点为文学化改编，不作为已考证历史事故的复现。\n正式公开提交或发行前，请确认相关改编权利与许可。",[["章节选择",chapter_menu],["返回标题",main_menu],["退出",quit_game]])
func chapter_title()->String:return {"CAMP":"第一幕 · 最后一批棉衣","MARCH":"第二幕 · 漫长的队伍","STORM":"第三幕 · 风雪中的行军","SEARCH":"第四幕 · 沿来路寻找","DISCOVERY":"第五幕 · 岩壁边的人影","SALUTE":"向牺牲的战友致敬","CONTINUE":"第六幕 · 继续前进","COMPLETE":"丰碑 · 雪线之上"}.get(stage,"")
func instruction()->Dictionary:
	var title=chapter_title();var hint=""
	match stage:
		"CAMP":hint="F 查看物资 · E 抱起衣物，再送到需要的人手中" if stats.delivered<3 else "回到那位带褐色挎包的老战士身边"
		"MARCH":hint="顺着行军队伍上山 · 道路受阻时 E 帮忙清理"
		"STORM":hint="借岩避风 · F 看清岩旁的队伍标记，再到前方避风岩 Q 发信号"
		"SEARCH":hint="返回一段来路 · F 辨认雪地痕迹和熟悉的随身物件"
		"DISCOVERY":hint="靠近老战士 E 蹲下查看" if not flags.get("inspected",false) else ("F 查看衣物" if not flags.get("coat_seen",false) else "F 看看扣着的挎包和记录 · 等周班长跟上")
		"SALUTE":hint="E 立正，向牺牲的战友敬礼"
		"CONTINUE":hint="重新加入队伍，走过最后一段山路"
	return {"title":title,"action":hint}
func interaction_hint()->String:
	if action!="":return ""
	if stage=="CAMP" and player.carrying:return "把衣物送到小田、老赵和许成身旁 · E 交接" if not flags.get("gave_giver",false) else "许成把衣物让给了阿木 · E 交接"
	return ""
func save_checkpoint():
	if not built or not started:return
	var data={"version":41,"chapter":"memorial","stage":stage,"flags":flags.duplicate(true),"stats":stats.duplicate(true),"position":[safe_point.x,safe_point.y,safe_point.z],"actors":[],"elapsed":elapsed,"retries":retries,"weather_clock":weather.clock,"observed":observation.found.duplicate(true),"shelters":weather.shelter_visits.duplicate(true),"stock":stock,"carrying":player.carrying,"crowd_clock":crowd.clock,"action":action,"action_clock":action_clock,"action_target":action_target,"action_duration":action_duration,"action_beat":action_beat,"stage_history":stage_history.duplicate(true),"reveal_silence":reveal_music_silence}
	for a in actors():data.actors.append(a.snapshot())
	data.version=412
	data.director=director.snapshot()
	data.crowd_s=crowd.units.map(func(u):return float(u.s))
	if save_store.write(data):last_checkpoint=data.duplicate(true)
func restore_checkpoint(data:Dictionary):
	audio.clear_voice();stage=data.stage;flags=data.flags.duplicate(true);stats=data.stats.duplicate(true);stock=int(data.stock);elapsed=float(data.elapsed);retries=int(data.retries);weather.clock=float(data.weather_clock);crowd.restore_clock(float(data.crowd_clock));observation.reset();observation.found=data.get("observed",{}).duplicate(true);weather.shelter_visits=data.get("shelters",{}).duplicate(true)
	var p=data.position;safe_point=Vector3(p[0],p[1],p[2]);player.restore(safe_point);player.reset_physics_interpolation();player.carrying=data.carrying;parcel.visible=player.carrying;parcel.position=Vector3(0,1.04,.35);previous_position=player.position
	for i in actors().size():actors()[i].restore_snow(data.actors[i])
	crowd.restore_state(float(data.crowd_clock),data.get("crowd_s",[]));world.reset_parcels(stock)
	if not flags.get("obstacle_cleared",false):world.reset_obstacle()
	if flags.get("obstacle_cleared",false) and not world.obstacle_cleared:world.clear_obstacle()
	started=true;paused=false;failed=false;outro_active=false;camera_observing=false;action=data.get("action","");action_clock=float(data.get("action_clock",0));action_target=data.get("action_target","");action_duration=float(data.get("action_duration",0));action_beat=int(data.get("action_beat",0));stage_history=data.get("stage_history",[]).duplicate(true);reveal_music_silence=float(data.get("reveal_silence",0));act_clock=0
	player.locked=action!="" or stage=="SALUTE";hud.hide_menu();hud.center_title.text="";_reset_camera();last_checkpoint=data.duplicate(true);Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	if action!="":
		player.visual.pose(action if action in ["take","clear","inspect","salute"] else "handover" if action=="give" else "");player.visual.narrative_clock=action_clock
		player.visual.mode="pickup" if action in ["take","clear","inspect"] else "idle"
		for a in actors():
			if a.pose_name in ["handover","salute"]:a.visual.narrative_clock=action_clock
	if data.has("director"):director.restore(data.director)
	if stage=="COMPLETE":_settlement()
func _start_memorial_replay():
	var runner=load("res://qa/memorial_replay.gd").new();get_tree().root.add_child(runner);runner.run(self)
func _smoke_memorial():
	await get_tree().create_timer(.4).timeout;print("MEMORIAL_SMOKE ","PASS" if actors().size()==8 and world.terrain and crowd.mid_count==24 and crowd.far_count==48 else "FAIL");get_tree().quit()
func toggle_pause():
	if failed or stage=="COMPLETE":return
	paused=not paused;_apply_control_lock()
	if paused:
		save_checkpoint();hud.show_menu("丰碑 · 暂停","动作与人物状态会随检查点保存。\nWASD 移动 · F 观察 · E 交互 · Q 信号",[["继续",toggle_pause],["从检查点重试",retry_checkpoint],["声音与画质",settings_menu],["返回标题",main_menu]])
	else:hud.hide_menu();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func _apply_control_lock():player.locked=paused or action!="" or stage=="SALUTE" or not flags.get("intro_done",false) or outro_active or flags.get("at_pass",false)
func settings_menu():
	hud.show_menu("声音与画质","音乐 %d%% · 环境音 %d%%\n画质：%s"%[roundi(audio.music_volume*100),roundi(audio.effect_volume*100),"高" if high_quality else "性能优先"],[["音乐降低",func():audio.music_volume=maxf(0,audio.music_volume-.15);settings_menu()],["音乐提高",func():audio.music_volume=minf(1,audio.music_volume+.15);settings_menu()],["环境音降低",func():audio.effect_volume=maxf(0,audio.effect_volume-.15);settings_menu()],["环境音提高",func():audio.effect_volume=minf(1,audio.effect_volume+.15);settings_menu()],["切换画质",func():high_quality=not high_quality;world.set_quality(high_quality);settings_menu()],["返回",func():paused=false;_apply_control_lock();hud.hide_menu() if started else main_menu()]])

func _honor_gathered()->bool:
	for a in actors():
		if a!=quartermaster and (a.moving or a.position.distance_to(world.MEMORIAL)>7):return false
	return true


func _start_animation_lab():
	var runner=load("res://qa/animation_lab.gd").new();get_tree().root.add_child(runner);runner.run(self)

func _start_role_audio_lab():
	var runner=load("res://qa/role_audio_lab.gd").new();get_tree().root.add_child(runner);runner.run(self)
