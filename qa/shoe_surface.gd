extends RefCounted
# QA only: evaluates actual skinned shoe vertices; never bakes or modifies the character mesh.
var cache:Dictionary={}
func sample(actor)->Dictionary:
 var v=actor.visual;var sk=v.skeleton;var result={"l":INF,"r":INF};var id=actor.get_instance_id()
 if not cache.has(id):
  var items=[]
  for mesh in v.rig.find_children("*shoes*","MeshInstance3D",true,false):
   var a=mesh.mesh.surface_get_arrays(0);var bind_map=[]
   for i in mesh.skin.get_bind_count():bind_map.append(sk.find_bone(mesh.skin.get_bind_name(i)) if mesh.skin.get_bind_name(i)!="" else mesh.skin.get_bind_bone(i))
   items.append({"node":mesh,"vertices":a[Mesh.ARRAY_VERTEX],"bones":a[Mesh.ARRAY_BONES],"weights":a[Mesh.ARRAY_WEIGHTS],"map":bind_map})
  cache[id]=items
 for item in cache[id]:
  var transforms=[];var mesh=item.node
  for k in item.map.size():transforms.append(sk.get_bone_global_pose(item.map[k])*mesh.skin.get_bind_pose(k))
  var influences=int(item.bones.size()/item.vertices.size())
  for i in item.vertices.size():
   var p=Vector3.ZERO
   for k in influences:
    var index=i*influences+k;var weight=item.weights[index]
    if weight>.00001:p+=(transforms[item.bones[index]]*item.vertices[i])*weight
   var world=mesh.to_global(p);var side="l" if item.vertices[i].x>0 else "r"
   var hit=actor.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.4,world-Vector3.UP*.8,1))
   if not hit.is_empty():result[side]=minf(result[side],world.y-hit.position.y)
 return result
