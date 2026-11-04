extends RefCounted
## Chapter-only pose layer: anatomical palm frame, then bounded finger fitting.
## The animation and actor transforms remain owned by the established controller.
var skeleton:Skeleton3D
var frames:Dictionary={}
var chains:Dictionary={}
var wrist_basis:Dictionary={}
var previous_profile:=""
func setup(value:Skeleton3D):
	skeleton=value
	for side in ["r","l"]:
		var hand=skeleton.find_bone("hand_"+side); var rest=skeleton.get_bone_global_rest(hand)
		var forward=rest.basis.inverse()*(skeleton.get_bone_global_rest(skeleton.find_bone("middle_01_"+side)).origin-rest.origin)
		var across=rest.basis.inverse()*(skeleton.get_bone_global_rest(skeleton.find_bone("index_01_"+side)).origin-skeleton.get_bone_global_rest(skeleton.find_bone("pinky_01_"+side)).origin)
		var normal=forward.cross(across).normalized()*(-1.0 if side=="r" else 1.0)
		frames[side]=_frame(forward,normal)
		for finger in ["thumb","index","middle","ring","pinky"]:
			var bones=[]; var rests=[]
			for joint in [1,2,3]:
				var bone=skeleton.find_bone("%s_0%d_%s"%[finger,joint,side]); bones.append(bone); rests.append(skeleton.get_bone_rest(bone))
			chains[side+finger]={"bones":bones,"rests":rests}
func clear(): wrist_basis.clear(); previous_profile=""
func _frame(forward:Vector3,normal:Vector3)->Basis:
	var z=forward.normalized(); var x=normal.cross(z).normalized(); return Basis(x,z.cross(x).normalized(),z)
func targets(profile:String,prop:Node3D)->Array:
	if profile=="ladle":return [prop.to_global(Vector3(-.06,.24,-.13)),prop.to_global(Vector3(.16,.11,-.07))]
	if profile=="hook":
		var eye=prop.to_global(Vector3(0,.058,0))
		return [eye+prop.global_basis.orthonormalized()*Vector3(-.045,-.035,-.105),eye+prop.global_basis.orthonormalized()*Vector3(.20,-.12,-.015)]
	if profile=="rod":
		var slope=float(prop.get_meta("shaft_slope",.115))
		var stroke=float(prop.get_meta("reel_stroke",0.0))
		return [prop.to_global(Vector3(-.085,slope*.1-.04,-.12)),prop.to_global(Vector3(.085,slope*(.46+stroke)-.04,.24+stroke))]
	if profile=="parcel": return [prop.to_global(Vector3(-.10,.025,-.095)),prop.to_global(Vector3(.10,.025,-.095))]
	return [prop.to_global(Vector3(-.15,.075,-.075)),prop.to_global(Vector3(.15,.075,-.075))]
func apply(profile:String,prop:Node3D,delta:float):
	if not is_instance_valid(prop): clear(); return
	if profile!=previous_profile: wrist_basis.clear(); previous_profile=profile
	for side in ["r","l"]:
		if profile in ["hook","ladle"] and side=="l": continue
		var sign_value=-1.0 if side=="r" else 1.0
		var forward=Vector3(.25,0,1) if profile=="hook" else Vector3(0,-.18,1)
		var normal=Vector3(-sign_value,0,0)
		if profile=="rod": forward=Vector3(0,float(prop.get_meta("shaft_slope",.115)),1)
		elif profile=="ladle":forward=Vector3(.1,.65,1)
		var world=prop.global_basis.orthonormalized()
		var desired=_frame(skeleton.global_basis.inverse()*(world*forward),skeleton.global_basis.inverse()*(world*normal))*frames[side].inverse()
		var hand=skeleton.find_bone("hand_"+side); var pose=skeleton.get_bone_global_pose(hand)
		var last=wrist_basis.get(side,pose.basis.orthonormalized())
		pose.basis=last.slerp(desired,1-exp(-delta*16)); wrist_basis[side]=pose.basis
		skeleton.set_bone_global_pose_override(hand,pose,1,true)
		skeleton.force_update_all_bone_transforms()
		for finger in ["thumb","index","middle","ring","pinky"]:
			var goal:Vector3
			var order=["index","middle","ring","pinky"].find(finger)
			if profile=="hook":
				if finger not in ["thumb","index"]:
					var chain=chains[side+finger]; var rotations=[]
					for bone in chain.bones: rotations.append(skeleton.get_bone_pose_rotation(bone).slerp(Quaternion.IDENTITY,.58))
					var poses=_poses(chain,rotations,pose)
					for joint in 3: skeleton.set_bone_global_pose_override(chain.bones[joint],poses[joint],1,true)
					continue
				goal=prop.to_global(Vector3(0,.058,.0028 if finger=="index" else -.0028))
			elif profile=="ladle":goal=prop.to_global(Vector3(-.006,.30 if finger=="thumb" else .29+(order-1.5)*.015,-.048))
			elif profile=="rod":
				var anchor=0.0 if side=="r" else .36+float(prop.get_meta("reel_stroke",0.0))
				var along=anchor+(.025 if finger=="thumb" else (order-1.5)*.025)
				goal=prop.to_global(Vector3(sign_value*.013,float(prop.get_meta("shaft_slope",.115))*(along+.22)+(.016 if finger=="thumb" else -.006),along))
			elif profile=="parcel": goal=prop.to_global(Vector3(sign_value*.045,.02,(order-1.5)*.019))
			else:
				goal=prop.to_global(Vector3(sign_value*(.108 if finger=="thumb" else [.100,.096,.084,.072][order]),.103 if finger=="thumb" else [.083,.053,.025,.008][order],-.02 if finger=="thumb" else [.065,.055,.045,.035][order]))
			_fit(side,finger,skeleton.to_local(goal))
func _poses(chain:Dictionary,rotations:Array,parent:Transform3D)->Array:
	var output=[]; var value=parent
	for i in 3:
		var rest:Transform3D=chain.rests[i]
		value=value*Transform3D(rest.basis*Basis(rotations[i]),rest.origin); output.append(value)
	return output
func _fit(side:String,finger:String,goal:Vector3):
	var chain=chains[side+finger]; var rotations=[]
	for bone in chain.bones: rotations.append(skeleton.get_bone_pose_rotation(bone))
	var parent=skeleton.get_bone_global_pose(skeleton.find_bone("hand_"+side))
	var poses=_poses(chain,rotations,parent)
	for iteration in 10:
		for joint in [2,1,0]:
			var end:Vector3=poses[2]*Vector3(0,.021,0)
			var from=end-poses[joint].origin; var to=goal-poses[joint].origin
			if from.length_squared()<.0000001 or to.length_squared()<.0000001: continue
			var turn=Quaternion(from.normalized(),to.normalized())
			var angle=turn.get_angle()
			if angle>.32: turn=Quaternion.IDENTITY.slerp(turn,.32/angle)
			var basis:Basis=poses[joint].basis
			var local_turn=(basis.inverse()*Basis(turn)*basis).get_rotation_quaternion()
			rotations[joint]=(rotations[joint]*local_turn).normalized()
			poses=_poses(chain,rotations,parent)
		if (poses[2]*Vector3(0,.021,0)).distance_squared_to(goal)<.000001: break
	for i in 3: skeleton.set_bone_global_pose_override(chain.bones[i],poses[i],1,true)
	skeleton.force_update_all_bone_transforms()
