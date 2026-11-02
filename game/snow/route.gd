extends RefCounted
# Compressed, fictional playable route. Coordinates are metres relative to camp.
const POINTS=[Vector3(0,0,40),Vector3(0,3,17),Vector3(-15,5,5),Vector3(15,7,0),Vector3(26,10,-22),Vector3(12,14,-45),Vector3(0,17,-65),Vector3(-15,24,-85),Vector3(10,30,-109),Vector3(24,38,-136),Vector3(38,40,-146),Vector3(12,47,-166),Vector3(8,49,-178),Vector3(-3,49,-179),Vector3(-5,50,-185),Vector3(-21,54,-202),Vector3(-28,58,-219),Vector3(-12,62,-238),Vector3(10,66,-250),Vector3(14,68,-262),Vector3(30,73,-279),Vector3(22,78,-300),Vector3(1,84,-312),Vector3(-14,91,-329),Vector3(-12,97,-350),Vector3(4,104,-367),Vector3(18,112,-387),Vector3(0,119,-405)]
var lengths:Array[float]=[]
var total:=0.0
func _init():
	lengths.append(0.0)
	for i in POINTS.size()-1:total+=Vector2(POINTS[i].x-POINTS[i+1].x,POINTS[i].z-POINTS[i+1].z).length();lengths.append(total)
func nearest(p:Vector3)->Dictionary:
	var distance=INF;var result={}
	for i in POINTS.size()-1:
		var a=Vector2(POINTS[i].x,POINTS[i].z);var b=Vector2(POINTS[i+1].x,POINTS[i+1].z);var v=Vector2(p.x,p.z)
		var t=clampf((v-a).dot(b-a)/(b-a).length_squared(),0,1);var q=a.lerp(b,t);var d=v.distance_to(q)
		if d<distance:
			distance=d;var tangent=(b-a).normalized()
			result={"index":i,"t":t,"s":lerpf(lengths[i],lengths[i+1],t),"distance":d,"signed":(v-q).dot(Vector2(-tangent.y,tangent.x)),"height":lerpf(POINTS[i].y,POINTS[i+1].y,t),"tangent":Vector3(tangent.x,0,tangent.y)}
	return result
func at(s:float)->Vector3:
	for i in POINTS.size()-1:
		if s<=lengths[i+1]:return POINTS[i].lerp(POINTS[i+1],clampf((s-lengths[i])/(lengths[i+1]-lengths[i]),0,1))
	return POINTS[-1]
func sample(p:Vector3)->Vector4:
	var best=INF;var result=Vector4.ZERO;var v=Vector2(p.x,p.z)
	for i in POINTS.size()-1:
		var a=Vector2(POINTS[i].x,POINTS[i].z);var b=Vector2(POINTS[i+1].x,POINTS[i+1].z)
		var t=clampf((v-a).dot(b-a)/(b-a).length_squared(),0,1);var q=a.lerp(b,t);var d=v.distance_squared_to(q)
		if d<best:
			best=d;var tangent=(b-a).normalized();result=Vector4((v-q).dot(Vector2(-tangent.y,tangent.x)),lerpf(POINTS[i].y,POINTS[i+1].y,t),sqrt(d),lerpf(lengths[i],lengths[i+1],t))
	return result
