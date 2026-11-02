extends RefCounted
# Every task state has one concrete instruction, an action and a named target.
var mission
var route_key=""
var route_index=0
var route:Array=[]
func setup(m): mission=m
func data()->Dictionary:
	var id=mission.ledger.current
	var state=mission.current_status()
	var d={"title":str(state.get("objective","继续前进")),"body":"跟随金色光圈与地面路标。","action":str(state.get("hint","")),"target":"任务目标","point":state.get("waypoint",Vector3.INF),"mode":"walk","progress":float(state.get("progress",0)),"route":[]}
	var p=mission.player.position
	var key=id
	match id:
		"march":
			var mod=mission.march
			if not mod.jumped: d.merge({"title":"跨过前方倒木","body":"走近横在路上的木头，按住 W 同时跳过。","action":"W 前进 + 空格 跳跃","target":"倒木"},true)
			elif not mod.supply: d.merge({"title":"领取左前方的接应物资","body":"走到金色光圈下的物资包旁，取走绳索和弹药。","action":"靠近后按 E 领取","target":"接应物资"},true)
			else: d.merge({"title":"沿山路前往桥头","body":"向前走到金色路标，随后开始观察桥面。","action":"WASD 移动 · Shift 奔跑","target":"桥头山路"},true)
		"recon":
			var mod=mission.recon
			if mod.found.size()<3:
				if not mod.observing:
					d.merge({"title":"到桥头观察桥面","body":"站到观察路标附近，进入观察后找出三个关键位置。","action":"按 F 进入观察","target":"观察位置","point":Vector3(0,1,16)},true)
				else:
					for target in ["firepoint","gap","cover"]:
						if target not in mod.found:
							d.merge({"title":"观察："+str(mod.targets[target].title),"body":"转动鼠标，将该目标置于准星内并保持片刻。已发现 %d/3。"%mod.found.size(),"action":"鼠标 找目标 · F 退出观察","target":str(mod.targets[target].title),"point":mod.target_point(target),"mode":"observe"},true); break
			else: d.merge({"title":"选择一条接应路线","body":"A 是左侧近桥短路；B 是右侧掩体路线。走到路牌旁确认。","action":"F 退出观察 · 路牌旁按 E","target":"A 路牌","point":Vector3(-1.1,1,11)},true)
		"escort":
			var mod=mission.escort
			if mod.assembling: d.merge({"title":"等待阿木抵达接应点","body":"先站稳，观察对岸火力点；战友就位后再开始掩护。","action":"可以移动 · 右键瞄准观察","target":"战友接应点"},true)
			elif mod.route=="B" and not mod.blocker_cleared: d.merge({"title":"清开侧路上的木箱","body":"靠近金色标记的木箱，为队友清出通道。","action":"靠近木箱按 E","target":"挡路木箱"},true)
			elif mod.moving: d.merge({"title":"掩护正在转移的阿木","body":"保持射击对岸火力点；战友会走到下一处掩体。","action":"右键瞄准 · 左键射击 · R 装填","target":"阿木","mode":"observe"},true)
			elif mod.window_remaining>0: d.merge({"title":"现在通知阿木前进","body":"压制窗口已经建立，及时发出转移信号。","action":"按 Q 发信号","target":"战友接应点","point":mod.safe_position+Vector3.UP,"mode":"work"},true)
			else: d.merge({"title":"压制对岸火力点 %d"%(mod.leg+1),"body":"瞄准橙色标记的敌人并命中，建立安全窗口。弹药不足可到补给箱按 E。","action":"右键瞄准 · 左键射击 · R 装填","target":"火力点 %d"%(mod.leg+1),"mode":"aim"},true)
		"repair":
			var mod=mission.repair; var step=mod.step
			key+="_%d_%s_%d"%[mod.site,step,mod.prep_round]
			d.target="第一处修桥点" if mod.site==0 else "第二处修桥点"
			match step:
				"preparing": d.merge({"title":"检查并固定木料","body":"自动完成备料。期间可以移动、观察对岸；不再反复对齐绑绳。","action":"备料完成后 E 呼叫战友","target":"备料木板","mode":"work"},true)
				"auto_secure": d.merge({"title":"共同固定桥板","body":"固定完成后战友即可继续通过。","action":"稍候 · R 取消","mode":"work","target":"桥板支撑"},true)
				"parked": d.merge({"title":"木板已放稳，可掩护战友","body":"右键瞄准对岸、左键射击。压住火力后回到木板朝桥一端继续搬运。","action":"射击掩护 · 松开右键，板端 E 续搬","target":"续搬握持点","point":mod.pickup_position()+Vector3.UP},true)
				"select":
					d.merge({"title":"%d/2 · 到备料点选择木板"%(mod.site+1),"body":"金色标记指向完好木板。裂板需多绑一道绳；朽裂木板不能使用。","action":"靠近木板端部按 E 检查","target":"完好木板","point":mod.material_position("good")+Vector3.UP},true)
					if mod.site==1:
						if p.z> -8.0: d.route.append(Vector3(0,0,-7.2))
						if p.z> -12: d.route.append(Vector3(0,0,-11.9))
						if p.z> -20: d.route.append(Vector3(0,0,-20.5))
				"position":
					var horizontal=mod.prep_round==0
					d.merge({"title":"把木板定位到白区","body":"横移偏差 %.0f%%，对齐至 ±17%% 内。"%(mod.lateral*100) if horizontal else "纵向偏差 %.0f%%，对齐至 ±17%% 内。"%(mod.depth*100),"action":"A / D 调整 → E 确认 · R 取消" if horizontal else "W / S 调整 → E 确认 · R 取消","mode":"work","target":"备料工作台"},true)
				"tie","secure": d.merge({"title":"按住 E 绑紧绳索","body":"固定 %d%% · 张力 %d%%。用 A / D 保持在 22—82%% 范围。"%[int(mod.hold_progress/1.4*100),int(mod.tension*100)],"action":"按住 E · A / D 修正 · R 取消","mode":"work","target":"固定位置"},true)
				"check","place_check": d.merge({"title":"检查木板是否固定牢靠","body":"绑绳已完成，检查后才能继续搬运或开放桥面。","action":"按 空格 检查 · R 取消","mode":"work","target":"检查位置"},true)
				"pickup":
					var grip=mod.pickup_position()
					d.merge({"title":"绕到朝桥的一端，呼叫阿木","body":"先绕过工作台，到金色光圈里的握持点；不用在原来的绑绳位置等。","action":"光圈内按 E 呼叫 · R 取消","target":"取板握持点","point":grip+Vector3.UP},true)
					if p.z>grip.z+.5:
						d.route=[Vector3(grip.x+1,0,p.z),Vector3(grip.x+1,0,grip.z)]
				"join","npc_ready": d.merge({"title":"在板端等阿木接住另一头","body":"阿木正在按路线靠近。留在光圈附近；离开或按 R 可取消。","action":"等待队友就位 · R 取消","mode":"work","target":"等候握持点","point":mod.pickup_position()+Vector3.UP},true)
				"lifting": d.merge({"title":"两人正在一起抬板","body":"抬稳后即可用 WASD 搬运，无需反复按 E。","action":"稍候 · R 取消","mode":"work","target":"共同抬板"},true)
				"carry":
					d.merge({"title":"把木板送到缺口前","body":"战友正在桥上推进。右键可放下木板转为掩护，随后靠近板端E续搬。","action":"目标处 E 放板 · 右键转掩护","target":"放板位置","point":mission.world.get_v2_gap(mod.site).approach+Vector3.UP},true)
					if mod.site==0 and p.z>3: d.route=[Vector3(0,0,3.2)]
				"lowering": d.merge({"title":"两人正在放下木板","body":"先放低，再送上桥面支撑。动画完成后会提示下一步。","action":"等待放稳 · R 取消","mode":"work","target":"缺口支撑"},true)
				"align": d.merge({"title":"把板端对齐两侧支撑","body":"横移偏差 %.0f%%。第二处还可用 W / S 调整纵向。"%(mod.lateral*100),"action":"A / D 调整 → E 确认 · R 取消","mode":"work","target":"桥板支撑"},true)
				"recover": d.merge({"title":"已释放控制，可以重新尝试","body":"木板正在返回备料点，随后跟随金色光圈取板。","action":"WASD 自由移动","mode":"work","target":"备料点"},true)
		"traversal":
			var mod=mission.traversal; key+="_"+mod.phase
			if mod.phase=="approach": d.merge({"title":"到右侧抓索点","body":"沿修好的桥面前进，走到桥面尽头右侧的光圈。","action":"光圈旁按 E 抓索","target":"右侧抓索点"},true)
			elif mod.phase in ["climb_a","climb_b"]: d.merge({"title":"沿铁索前往下一个支点","body":"看平衡条：向右倾按 A，向左倾按 D。松开 W 可停下稳住。","action":"W 前进 · A / D 反向调平衡","mode":"work","target":"安全支点"},true)
			elif mod.phase=="align": d.merge({"title":"摆正支点上的松板","body":"用 A / D 将偏差调至 ±18% 内，再检查。","action":"A / D 调整 → 空格 确认","mode":"work","target":"松动支撑"},true)
			elif mod.phase=="tension": d.merge({"title":"与阿木收紧支撑绳","body":"按住 E 张紧，在 35%—85% 范围内按空格。","action":"按住 E → 空格 检查","mode":"work","target":"支撑绳"},true)
			else: d.merge({"title":"支点安全，准备继续过索","body":"靠近金色光圈，跟随当前操作提示。","action":str(state.hint),"target":"铁索支点"},true)
		"relay":
			var mod=mission.relay; key+="_"+mod.phase
			if mod.phase=="observe": d.merge({"title":"观察桥亭前落下的横档","body":"按住 F，转动鼠标将横档放进准星，保持片刻。","action":"按住 F + 鼠标观察","mode":"observe","target":"落下的横档"},true)
			elif mod.phase in ["signal","ready"]: d.merge({"title":"走到右侧绳轮发信号","body":"先按 Q 呼叫两位战友；他们就位后按 E 握住引绳。","action":"绳轮旁 Q 呼叫 → E 握绳","target":"右侧绳轮"},true)
			elif mod.phase=="pull": d.merge({"title":"对齐引绳并抬起横档","body":"先 A / D 对齐至 ±20% 内；再按住 E 拉起，最后空格检查。","action":"A / D 对齐 → 按住 E → 空格","mode":"work","target":"引绳操作"},true)
			else: d.merge({"title":"穿过桥亭，确认战友通过","body":"横档已经抬起。等待两位战友通过后，到亭内光圈确认。","action":"WASD 前进 · 亭内按 E","target":"桥亭确认点"},true)
		"complete": d.merge({"title":"全部任务完成","body":"通道已经打通，后续部队正在通过。","action":"返回标题或退出游戏","mode":"work"},true)
	key+=":"+str(d.title)+":"+str(d.point)
	if key!=route_key:
		route_key=key; route_index=0; route=d.route.duplicate()
		if d.point!=Vector3.INF: route.append(d.point)
	while route_index<route.size()-1 and Vector2(p.x-route[route_index].x,p.z-route[route_index].z).length()<.65: route_index+=1
	d.next=route[route_index] if route_index<route.size() else d.point
	d.tag={"march":"01 / 06 · 山路接应","recon":"02 / 06 · 桥头观察","escort":"03 / 06 · 压制掩护","repair":"04 / 06 · 双人修桥","traversal":"05 / 06 · 铁索通行","relay":"06 / 06 · 桥亭接力","modern":"尾声 · 结构重建"}.get(id,"任务指引")
	return d
