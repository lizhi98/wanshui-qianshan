extends RefCounted
# V4.1.2: 30% shorter horizontal route; keeps the existing logical landmarks. Coordinates are metres relative to camp.
const POINTS=[Vector3(0.000,0.000,40.000),Vector3(0.000,3.000,23.900),Vector3(-10.500,5.000,15.500),Vector3(10.500,7.000,12.000),Vector3(18.200,10.000,-3.400),Vector3(8.400,14.000,-19.500),Vector3(0.000,17.000,-33.500),Vector3(-10.500,24.000,-47.500),Vector3(7.000,30.000,-64.300),Vector3(16.800,38.000,-83.200),Vector3(26.600,40.000,-90.200),Vector3(8.400,47.000,-104.200),Vector3(5.600,49.000,-112.600),Vector3(-2.100,49.000,-113.300),Vector3(-3.500,50.000,-117.500),Vector3(-14.700,54.000,-129.400),Vector3(-19.600,58.000,-141.300),Vector3(-8.400,62.000,-154.600),Vector3(7.000,66.000,-163.000),Vector3(9.800,68.000,-171.400),Vector3(21.000,73.000,-183.300),Vector3(15.400,78.000,-198.000),Vector3(0.700,84.000,-206.400),Vector3(-9.800,91.000,-218.300),Vector3(-8.400,97.000,-233.000),Vector3(2.800,104.000,-244.900),Vector3(12.600,112.000,-258.900),Vector3(0.000,119.000,-271.500)]
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
