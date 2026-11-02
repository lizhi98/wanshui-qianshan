extends Node3D
# Decals are emitted on skeletal foot plants, projected to real terrain normals.
var world
var marks:Array=[]
var pending:Array=[]
var gait:Dictionary={}
var clock:=0.0
var emitted:=0
var rejected_rock:=0
func clear_dynamic():
	for i in range(marks.size()-1,-1,-1):
		if not marks[i].clue:marks[i].node.queue_free();marks.remove_at(i)
	gait.clear()
const LIMIT=160
func queue_mark(point:Vector3,direction:Vector3,left:bool,clue:=false):pending.append([point,direction,left,clue])
func _physics_process(delta):
	if world.mission and world.mission.paused:return
	clock+=delta
	if not pending.is_empty():
		var todo=pending;pending=[]
		for row in todo:stamp(row[0],row[1],row[2],row[3])
	for i in range(marks.size()-1,-1,-1):
		var row=marks[i];var age=clock-float(row.time)
		if age>95 and not row.clue:row.node.queue_free();marks.remove_at(i)
		elif not row.clue:row.node.modulate.a=(1-smoothstep(60,95,age))*.88
func track(actor):
	if not actor or not actor.visual:return
	if not actor.is_on_floor() or Vector2(actor.velocity.x,actor.velocity.z).length()<.45:
		var idle_driver=actor.visual.get("contact_driver")
		if idle_driver:idle_driver.events.clear()
		return
	var driver=actor.visual.get("contact_driver")
	if driver:
		var id=actor.get_instance_id()
		if not gait.has(id):gait[id]={"last":"","position":actor.position-actor.global_basis.z}
		var state:Dictionary=gait[id]
		for event in driver.events:
			if event.side==state.last or actor.position.distance_to(state.position)<.22:continue
			if actor==world.mission.player:world.mission.audio.play_snow_footstep(actor,event)
			if stamp(event.point,actor.global_basis.z,event.side=="l"):state.last=event.side;state.position=actor.position
		driver.events.clear();return
	var id=actor.get_instance_id();var sk:Skeleton3D=actor.visual.skeleton
	if not gait.has(id):gait[id]={"l":{},"r":{},"last":"", "position":actor.position}
	var state:Dictionary=gait[id]
	for side in ["l","r"]:
		var bone=sk.find_bone("foot_"+side)
		if bone<0:continue
		var foot=sk.to_global(sk.get_bone_global_pose(bone).origin)
		var old:Dictionary=state[side];var height=foot.y-actor.position.y
		var dy=height-float(old.get("height",height));var descending=float(old.get("dy",0))< -.0002
		var planted=descending and dy>=-.0002 and height<.25
		if planted and state.last!=side and actor.position.distance_to(state.position)>.28:
			if stamp(foot,actor.global_basis.z,side=="l"):
				state.last=side;state.position=actor.position
		state[side]={"height":height,"dy":dy}
func stamp(point:Vector3,direction:Vector3,left:bool,clue:=false)->bool:
	var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*.8,point-Vector3.UP*1.8,1))
	if hit.is_empty():return false
	var parent=hit.collider.get_parent();var name_text=str(parent.name)
	if not ("Mountain" in name_text or "Trail" in name_text):rejected_rock+=1;return false
	if hit.normal.y<.5:return false
	var snow=world.has_method("snow_from_start") or hit.position.y>25
	var decal=Decal.new();add_child(decal);decal.name="LeftBoot" if left else "RightBoot"
	decal.texture_albedo=load("res://assets/memorial/footprints/sole_"+("snow" if snow else "mud")+("" if left else "_right")+".png")
	decal.texture_normal=load("res://assets/memorial/footprints/sole_normal"+("" if left else "_right")+".png");decal.normal_fade=.5
	decal.size=Vector3(.17,.32,.32);decal.modulate=Color(1,1,1,.88);decal.albedo_mix=.82
	decal.distance_fade_enabled=true;decal.distance_fade_begin=25;decal.distance_fade_length=15
	var up:Vector3=hit.normal;var forward=(direction-up*up.dot(direction)).normalized()
	if forward.length()<.5:forward=Vector3.FORWARD.slide(up).normalized()
	var right=up.cross(forward).normalized()
	decal.global_transform=Transform3D(Basis(right,up,forward).orthonormalized().rotated(up,.035 if left else -.035),hit.position+up*.035)
	if not left:decal.size.x*=.97
	marks.append({"node":decal,"time":clock,"clue":clue,"normal":up,"point":hit.position,"left":left})
	emitted+=1
	while marks.size()>LIMIT:
		var index=0
		for i in marks.size():
			if not marks[i].clue:index=i;break
		marks[index].node.queue_free();marks.remove_at(index)
	return true
