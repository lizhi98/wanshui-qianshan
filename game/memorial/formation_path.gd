extends RefCounted
# Visibility graph around stationary squad members. Produces ordinary waypoints.
const CLEARANCE=.74
func clear(a:Vector2,b:Vector2,obstacles:Array,escape:=false)->bool:
 for c in obstacles:
  var distance=a.distance_to(c)
  if escape and distance<CLEARANCE:
   if (b-a).dot(a-c)< -.0001:return false
   continue
  if Geometry2D.get_closest_point_to_segment(c,a,b).distance_to(c)<CLEARANCE-.001:return false
 return true
func plan(start:Vector2,goal:Vector2,obstacles:Array)->Array:
 var nodes:Array=[start,goal]
 for c in obstacles:
  for i in 16:
   var p=c+Vector2.from_angle(TAU*float(i)/16)*.98;var free=true
   for other in obstacles:
    if p.distance_to(other)<CLEARANCE:free=false;break
   if free:nodes.append(p)
 var costs:Array=[];var previous:Array=[];var used:Array=[]
 for n in nodes:costs.append(INF);previous.append(-1);used.append(false)
 costs[0]=0.0
 for iteration in nodes.size():
  var index=-1;var best=INF
  for i in nodes.size():
   if not used[i] and costs[i]<best:index=i;best=costs[i]
  if index<0:break
  if index==1:
   var result:Array=[];var cursor=1
   while cursor>0:result.push_front(nodes[cursor]);cursor=previous[cursor]
   return result
  used[index]=true
  for j in nodes.size():
   if used[j] or not clear(nodes[index],nodes[j],obstacles,index==0):continue
   var candidate=best+nodes[index].distance_to(nodes[j])
   if candidate<costs[j]:costs[j]=candidate;previous[j]=index
 return []
