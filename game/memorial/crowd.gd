extends Node3D
# Near actors use full skeletons elsewhere. Mid figures have articulated joints;
# the distant column shares eight MultiMeshes and has no collision or AI.
var mission
var units:Array=[]
var rig_pool:Array=[]
var rig_assignments:Dictionary={}
var slot_owners:Dictionary={}
var batches:Array=[]
var clock:=0.0
var frame_clock:=0.0
var peak_in_frame:=0
var mid_count:=24
var far_count:=48
var rng=RandomNumberGenerator.new()
const Props=preload("res://game/memorial/props.gd")
func setup(m):
	mission=m;rng.seed=41035
	for i in mid_count:
		var figure=Node3D.new();add_child(figure);var parts=[]
		for part in 8:
			var mesh=MeshInstance3D.new();mesh.mesh=_shape(part,10);mesh.material_override=Props.mat(_color(part,i));figure.add_child(mesh);parts.append(mesh)
		units.append({"node":figure,"parts":parts,"base":-20+i*6.6,"pace":rng.randf_range(.84,1.18),"phase":rng.randf()*TAU,"offset":rng.randf_range(-.65,.65),"s":-20+i*6.6})
	for part in 8:
		var node=MultiMeshInstance3D.new();var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.mesh=_shape(part,6);mm.instance_count=far_count;node.multimesh=mm;add_child(node)
		var mat=Props.mat(Color.WHITE);mat.vertex_color_use_as_albedo=true;node.material_override=mat;node.visibility_range_end=480;batches.append(node)
	for i in far_count:
		var base=80+i*11.0 if i<24 else -230+(i-24)*7.0
		units.append({"base":base,"pace":rng.randf_range(.73,1.07),"phase":rng.randf()*TAU,"offset":rng.randf_range(-.48,.48),"s":base})
	for i in 12:
		var actor=load("res://game/memorial/crowd_actor.gd").new();actor.name=["MarchLin","MarchAmu","MarchZhou"][i%3]+str(i);add_child(actor);actor.setup(mission);actor.hide();rig_pool.append(actor)
	_update(0)
func _shape(part:int,sides:int)->Mesh:
	if part==1:
		var head=SphereMesh.new();head.radius=.105;head.height=.23;head.radial_segments=sides;head.rings=5;return head
	if part==2:
		var cap=CylinderMesh.new();cap.top_radius=.11;cap.bottom_radius=.12;cap.height=.08;cap.radial_segments=sides;return cap
	var body=CapsuleMesh.new();body.radial_segments=sides;body.rings=4
	body.radius=.19 if part==0 else (.11 if part==7 else .067)
	body.height=.86 if part==0 else (.39 if part==7 else (.68 if part in [5,6] else .62))
	return body
func _color(part:int,i:int)->Color:
	if part==1:return Color("92715a")
	if part==7:return Color("585a40")
	return Color("556862").lerp(Color("81735a"),float(i%7)/8)
func _part(part:int,phase:float,moving:bool)->Transform3D:
	var p=[Vector3(0,1.0,0),Vector3(0,1.50,0),Vector3(0,1.63,0),Vector3(-.215,1.05,0),Vector3(.215,1.05,0),Vector3(-.10,.36,0),Vector3(.10,.36,0),Vector3(0,1.10,-.21)][part]
	var swing=sin(phase)*.37 if moving else sin(phase*.2)*.015
	var rotation=swing*(-1 if part in [3,6] else 1) if part in [3,4,5,6] else 0.0
	if part in [5,6]:p.y=.34+absf(swing)*.055
	return Transform3D(Basis(Vector3.RIGHT,rotation),p)
func _physics_process(delta):
	if not mission.started or mission.paused or mission.failed:return
	clock+=delta*(.35 if mission.stage=="CAMP" else 1.0);frame_clock+=delta
	_update(delta)
func _update(delta):
	var visible_count=0;var route=mission.world.route;var used_slots:Dictionary={}
	var solemn=mission.stage in ["DISCOVERY","SALUTE"]
	for i in units.size():
		var unit=units[i];var wait=solemn;var s=float(unit.s)
		var cap=route.lengths[4]-6-float(i%6)*.8
		if not mission.flags.get("obstacle_cleared",false) and s<cap and s+delta*unit.pace>=cap:wait=true
		if mission.stage=="STORM" and not mission.flags.get("storm_signal",false):
			var limit=route.lengths[9]-3-float(i%7)*.7
			if s<limit and s+delta*unit.pace>=limit:wait=true
		if not wait:s+=delta*unit.pace*(.35 if mission.stage=="CAMP" else 1.0)
		unit.s=s
		var segment=int(unit.get("segment",0))
		while segment<route.POINTS.size()-2 and s>route.lengths[segment+1]:segment+=1
		unit.segment=segment
		var fraction=clampf((s-route.lengths[segment])/(route.lengths[segment+1]-route.lengths[segment]),0,1)
		var p:Vector3=route.POINTS[segment].lerp(route.POINTS[segment+1],fraction)
		var forward:Vector3=route.POINTS[segment+1]-route.POINTS[segment];forward.y=0;forward=forward.normalized()
		if s<0:p=route.POINTS[0]+Vector3(unit.offset*4,0,-s*.6)
		elif s>route.total:p+=forward*(s-route.total)
		p+=forward.cross(Vector3.UP)*unit.offset
		if s<60 or s>route.total:p.y=mission.world.height_at(p)
		var heading=float(unit.get("heading",atan2(forward.x,forward.z)))
		heading=rotate_toward(heading,atan2(forward.x,forward.z),delta*2.8);unit.heading=heading
		var basis=Basis(Vector3.UP,heading);var base=Transform3D(basis,p)
		var active=s> -46 and s<route.total+28;var phase=clock*(3.1+unit.pace)+unit.phase
		var distance=mission.view.camera.global_position.distance_to(p)
		if rig_assignments.has(i) and (distance>72 or not active):
			var released=int(rig_assignments[i]);slot_owners.erase(released);rig_assignments.erase(i);rig_pool[released].visual.pose("")
		if distance<65 and active and not rig_assignments.has(i):
			for candidate in rig_pool.size():
				if not slot_owners.has(candidate):
					rig_assignments[i]=candidate;slot_owners[candidate]=i;rig_pool[candidate].visual.reset_pose();break
		var full=rig_assignments.has(i)
		if full:
			var slot=int(rig_assignments[i]);used_slots[slot]=true;var actor=rig_pool[slot]
			unit.ground_clock=float(unit.get("ground_clock",1.0))+delta
			if unit.ground_clock>.10:
				var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*1.5,p-Vector3.UP*2.0,1))
				unit.ground_bias=(hit.position.y if not hit.is_empty() else mission.world.height_at(p))-p.y;unit.ground_clock=0
			p.y+=float(unit.get("ground_bias",0));base.origin=p
			actor.show();actor.transform=base
			actor.visual.speed=0 if wait else unit.pace*(.35 if mission.stage=="CAMP" else 1.0);actor.visual.mode="idle" if wait else "walk"
			# Always clear a salute when marching resumes; slots stay bound to one unit.
			actor.visual.pose("salute" if mission.action=="salute" else "")
			if solemn:actor.look_at(Vector3(mission.quartermaster.position.x,p.y,mission.quartermaster.position.z),Vector3.UP,true)
			if mission.action=="salute":actor.visual.narrative_clock=mission.action_clock
		active=active and not full and distance>=65
		if i<mid_count:
			unit.node.visible=active;unit.node.transform=base
			for part in 8:unit.parts[part].transform=_part(part,phase,not wait)
		else:
			for part in 8:
				var transform=base*_part(part,phase,not wait)
				if not active:transform.origin.y=-1000
				batches[part].multimesh.set_instance_transform(i-mid_count,transform);batches[part].multimesh.set_instance_color(i-mid_count,_color(part,i))
		if active and mission.view.camera.is_position_in_frustum(p+Vector3.UP):visible_count+=1
	for i in rig_pool.size():
		if not used_slots.has(i):rig_pool[i].hide()
	peak_in_frame=maxi(peak_in_frame,visible_count)
func restore_clock(value:float):
	rig_assignments.clear();slot_owners.clear()
	clock=value
	for u in units:u.s=u.base+clock*u.pace;u.segment=0
	_update(0)
func restore_state(value:float,positions:Array):
	rig_assignments.clear();slot_owners.clear()
	clock=value
	for i in units.size():units[i].s=positions[i] if i<positions.size() else units[i].base+value*units[i].pace;units[i].segment=0
	_update(0)
