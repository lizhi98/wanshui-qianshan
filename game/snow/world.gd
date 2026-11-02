extends "res://game/remaster/world.gd"
var route=preload("res://game/snow/route.gd").new()
var terrain:MeshInstance3D
var collapse_root:Node3D
var debris:Array=[]
var collapse_time:=0.0
var collapse_active:=false
var collapse_blocker:StaticBody3D
var snow_material:ShaderMaterial
var clues:Dictionary={}
var footprint_nodes:Array=[]
var footprints
var footprint_last=Vector3.INF
var footprint_side:=false
var snow_powder:GPUParticles3D
var jump_centers:Array[float]=[]
var shelter_centers:Array[Vector3]=[]
var noise=FastNoiseLite.new()
var slide_cloud:GPUParticles3D
var detour_drift:MeshInstance3D
var drift_origin:=Vector3.ZERO
func _ready():
	rng.seed=19350612;noise.seed=121935;noise.frequency=.035
	_build_material();_environment()
	environment.fog_light_color=Color("b8cbd7");environment.fog_density=.0018;environment.volumetric_fog_density=.0011
	sun.rotation_degrees=Vector3(-29,-126,0);sun.light_color=Color("ffe6c6");sun.light_energy=1.35;sun.directional_shadow_max_distance=170
	snow_material=ShaderMaterial.new();snow_material.shader=load("res://game/snow/terrain.gdshader")
	snow_material.set_shader_parameter("rock_map",stone.albedo_texture);snow_material.set_shader_parameter("earth_map",earth.albedo_texture);snow_material.set_shader_parameter("rock_normal",stone.normal_texture)
	jump_centers=[route.lengths[21]+8.0,route.lengths[24]+8.5]
	for index in [7,8,9]:shelter_centers.append(route.POINTS[index])
	_build_ground();_dress();_make_clues();_collapse_setup();_powder()
	_build_walk_ribbon()
func _ground_height(x:float,z:float,_near_bank:bool=true)->float:return height_at(Vector3(x,0,z))
func height_at(p:Vector3)->float:
	var sample=route.sample(p);var signed=sample.x;var h=sample.y;var d=sample.z;var path_s=sample.w
	var rough=noise.get_noise_2d(p.x,p.z)*10.0+sin(p.x*.036+p.z*.021)*4.0
	var base=(40-p.z)*119.0/445.0+absf(p.x)*.10+rough
	var trail_width=1.2 if path_s>route.lengths[20] else 1.5
	var blend=1-smoothstep(trail_width,10.0,d)
	var mountain=lerpf(base,h,blend)
	if path_s>route.lengths[20] and signed< -trail_width:mountain-=smoothstep(trail_width,7.0,-signed)*7.0*blend
	for s in jump_centers:
		var across=absf(path_s-s)
		if across<.85 and d<3.3:mountain-=6.5*smoothstep(.85,.52,across)*smoothstep(3.3,2.7,d)
	# A short exposed rock step that must be jumped rather than walked through.
	var step_s=route.lengths[23]+5
	if path_s>step_s and path_s<step_s+7:mountain+=.72
	elif path_s>=step_s+7 and path_s<step_s+10:mountain+=.72*(1-(path_s-step_s-7)/3)
	for branch in [[Vector3(-15,5,5),Vector3(-18,8,-16)],[Vector3(8,49,-178),Vector3(8,54,-200)],[Vector3(-12,62,-238),Vector3(-29,64,-245)],[Vector3(12,47,-166),Vector3(2,48.5,-173)],[Vector3(2,48.5,-173),Vector3(-3,49,-179)]]:
		var a:Vector3=branch[0];var b:Vector3=branch[1];var v=Vector2(p.x,p.z);var start=Vector2(a.x,a.z);var end=Vector2(b.x,b.z)
		var t=clampf((v-start).dot(end-start)/(end-start).length_squared(),0,1);var dist=v.distance_to(start.lerp(end,t))
		if dist<3.4:mountain=lerpf(mountain,lerpf(a.y,b.y,t),1-smoothstep(1.3,3.4,dist))
	# A shallow ravine lets the ridge overlook genuinely see the waiting team.
	var sight_a=Vector2(14,-262);var sight_b=Vector2(-28,-219);var v=Vector2(p.x,p.z)
	var sight_t=clampf((v-sight_a).dot(sight_b-sight_a)/(sight_b-sight_a).length_squared(),0,1)
	var sight_distance=v.distance_to(sight_a.lerp(sight_b,sight_t))
	if sight_distance<8 and sight_t>.04 and sight_t<.98:
		var cap=lerpf(68,58,sight_t)-1.4
		mountain=lerpf(mountain,minf(mountain,cap),(1-smoothstep(3,8,sight_distance))*smoothstep(1.6,3.0,d))
	# Preserve the walkable investigation spur across the edge of that ravine.
	var spur_a=Vector2(-12,-238);var spur_b=Vector2(-29,-245)
	var spur_t=clampf((v-spur_a).dot(spur_b-spur_a)/(spur_b-spur_a).length_squared(),0,1)
	var spur_distance=v.distance_to(spur_a.lerp(spur_b,spur_t))
	if spur_distance<3.4:mountain=lerpf(mountain,lerpf(62,64,spur_t),1-smoothstep(1.3,3.4,spur_distance))
	return mountain
func _build_walk_ribbon():
	var mesh:Mesh;var shape:Shape3D
	if ResourceLoader.exists("res://assets/snow/terrain/trail_mesh.res") and not "--bake-snow" in OS.get_cmdline_user_args():mesh=load("res://assets/snow/terrain/trail_mesh.res");shape=load("res://assets/snow/terrain/trail_shape.res")
	else:
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(0)
		var count=int(ceil(route.total/.25))
		for i in count:
			for across in 8:
				var points=[]
				for offset in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
					var s=minf(route.total,(i+offset.x)*.25);var p=route.at(s);var side=route.nearest(p).tangent.cross(Vector3.UP)
					p+=side*(-1.6+(across+offset.y)*.4);p.y=height_at(p)+.016;points.append(p)
				for index in [0,1,2,1,3,2]:
					var lateral=across+(1 if index in [2,3] else 0)
					var wear=1-smoothstep(.6,1.6,absf(-1.6+lateral*.4))
					st.set_color(Color(wear,wear,wear));st.set_uv(Vector2(points[index].x,points[index].z)*.1);st.add_vertex(points[index])
		st.index();st.generate_normals();st.generate_tangents();mesh=st.commit();shape=mesh.create_trimesh_shape()
		if "--bake-snow" in OS.get_cmdline_user_args():ResourceSaver.save(mesh,"res://assets/snow/terrain/trail_mesh.res");ResourceSaver.save(shape,"res://assets/snow/terrain/trail_shape.res")
	# This ribbon refines collision only. Rendering it over the coarser terrain
	# creates intersecting triangles at bends; trail wear is baked into the ground.
	var node=Node3D.new();node.name="DetailedRockTrailCollision";add_child(node)
	var body=StaticBody3D.new();node.add_child(body);var collision=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
func _build_ground():
	if ResourceLoader.exists("res://assets/snow/terrain/ground_mesh.res") and not "--bake-snow" in OS.get_cmdline_user_args():
		terrain=MeshInstance3D.new();terrain.name="ContinuousMountainCollision";terrain.mesh=load("res://assets/snow/terrain/ground_mesh.res");terrain.material_override=snow_material.duplicate();terrain.material_override.set_shader_parameter("path_surface",true);add_child(terrain)
		var body=StaticBody3D.new();terrain.add_child(body);var collider=CollisionShape3D.new();collider.shape=load("res://assets/snow/terrain/ground_shape.res");body.add_child(collider)
		_build_far_ridges();return
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(0)
	var nx=200;var nz=500
	var grid=PackedVector3Array();grid.resize((nx+1)*(nz+1))
	for z in nz+1:
		for x in nx+1:
			var p=Vector3(-100+float(x),0,70-float(z));p.y=height_at(p);grid[z*(nx+1)+x]=p
	for iz in nz:
		for ix in nx:
			var verts=[]
			for offset in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
				verts.append(grid[(iz+offset.y)*(nx+1)+ix+offset.x])
			for index in [0,2,1,1,2,3]:
				var wear=1-smoothstep(.6,2.3,route.sample(verts[index]).z)
				st.set_color(Color(wear,wear,wear));st.set_uv(Vector2(verts[index].x,verts[index].z)*.1);st.add_vertex(verts[index])
	st.index();st.generate_normals();st.generate_tangents();terrain=MeshInstance3D.new();terrain.name="ContinuousMountainCollision";terrain.mesh=st.commit();terrain.material_override=snow_material.duplicate();terrain.material_override.set_shader_parameter("path_surface",true);add_child(terrain);terrain.create_trimesh_collision()
	if "--bake-snow" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://assets/snow/terrain")
		ResourceSaver.save(terrain.mesh,"res://assets/snow/terrain/ground_mesh.res");ResourceSaver.save(terrain.mesh.create_trimesh_shape(),"res://assets/snow/terrain/ground_shape.res")
	_build_far_ridges()
func _build_far_ridges():
	# Far ridges are part of the mountain panorama, never stepping platforms.
	for side in [-1,1]:
		for k in 4:
			var peak=MeshInstance3D.new();var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES);surface.set_smooth_group(0)
			for row in 32:
				for col in 36:
					var vertices=[]
					for o in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
						var x=(col+o.x-18)*6.0;var z=(row+o.y-16)*6.0;var r=Vector2(x*.75,z).length();var y=maxf(-15,(1-r/150)*120)+noise.get_noise_2d(x+k*143,z)*18
						vertices.append(Vector3(x+side*(150+k*22),y+45+k*16,z-40-k*110))
					for j in [0,1,2,1,3,2]:surface.set_uv(Vector2.ZERO);surface.add_vertex(vertices[j])
			surface.index();surface.generate_normals();peak.mesh=surface.commit();peak.material_override=snow_material;add_child(peak)
func make_rock(point:Vector3,radius:float,solid:=true)->MeshInstance3D:
	if solid:
		# Seat the rock in the lowest side of its footprint on uneven ground.
		for side in [Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK]:point.y=minf(point.y,height_at(point+side*radius*.8)-.1)
	var node=rock_meshes[rng.randi_range(0,rock_meshes.size()-1)].duplicate();node.transform=Transform3D.IDENTITY;add_child(node)
	var bounds=node.get_aabb();var factor=radius*2/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z));node.scale=Vector3.ONE*factor;node.rotation.y=rng.randf()*TAU;node.position=point-node.basis*Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	node.visibility_range_end=240
	if point.y>32:node.material_override=snow_material
	if solid:
		var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;node.add_child(body)
		var shape=CollisionShape3D.new();shape.shape=node.mesh.create_convex_shape(true,false);body.add_child(shape)
	return node
func _dress():
	for i in 175:
		var s=rng.randf()*route.total;var p=route.at(s);var tangent=route.nearest(p).tangent;var side=tangent.cross(Vector3.UP)
		p+=side*rng.randf_range(5,28)*(-1 if i%2 else 1)
		if route.sample(p).z<5.3:continue
		# Keep the optional investigation spur free of random blocking boulders.
		if p.x> -36 and p.x< -15 and p.z> -253 and p.z< -230:continue
		p.y=height_at(p)-.25;make_rock(p,rng.randf_range(.5,2.8),i%3==0)
	for index in [7,8,9]:
		var p=route.POINTS[index];var incoming=(p-route.POINTS[index-1]).normalized();var outgoing=(route.POINTS[index+1]-p).normalized()
		var normal=(incoming.cross(Vector3.UP)+outgoing.cross(Vector3.UP)).normalized()
		var rock_p=p+normal*4.8;rock_p.y=height_at(rock_p)-.4;make_rock(rock_p,2.7,true)
	# The visibly blocked first branch points away from the actual path.
	for i in 5:
		var p=Vector3(-17+float(i%2)*1.8,0,-12-float(i)*1.6);p.y=height_at(p)-.4;make_rock(p,2.1,true)
	for i in 18:
		var p=Vector3((-1 if i%2 else 1)*rng.randf_range(7,29),0,rng.randf_range(8,53));p.y=height_at(p);_tree(p,rng.randf_range(.45,.9))
func _print_track(point:Vector3,mat:Material,size_value:Vector2,parent:Node=null)->MeshInstance3D:
	if parent==null:parent=self
	var mesh=MeshInstance3D.new();mesh.mesh=PlaneMesh.new();mesh.mesh.size=size_value;mesh.material_override=mat;parent.add_child(mesh);mesh.position=point;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;return mesh
func _make_clues():
	var track=material(Color("3d4749"));var cloth=material(Color("8a4235"));cloth.cull_mode=BaseMaterial3D.CULL_DISABLED
	clues={"route":{"point":Vector3(18,0,-6),"kind":"上行脚印"},"false_route":{"point":Vector3(-17,0,-6),"kind":"落石下断续的脚印"},"ridge_false":{"point":Vector3(-27,0,-243),"kind":"断崖前消失的脚印"},"ridge":{"point":Vector3(3,0,-248),"kind":"岩旁布条与上行脚印"}}
	for key in clues:
		var p:Vector3=clues[key].point;p.y=height_at(p)+.035;clues[key].point=p
		var direction=route.nearest(p).tangent
		if key=="false_route":direction=Vector3(-.14,0,-.99)
		if key=="ridge_false":direction=Vector3(-1,0,-.4).normalized()
		for j in 9:
			var q=p+direction*.46*j+direction.cross(Vector3.UP)*(-.13 if j%2 else .13);q.y=height_at(q)+.022
			_footprints().queue_mark(q,direction,j%2==0,true)
		if key=="ridge":
			var rock_p=p+Vector3(1.2,0,0);rock_p.y=height_at(rock_p)-.15;make_rock(rock_p,.65,true)
			var mesh=_print_track(p+Vector3(.5,1.05,0),cloth,Vector2(.18,.62));mesh.rotation.x=PI/2;mesh.rotation.z=.3
			clues[key]["focus"]=mesh.position
func _collapse_setup():
	collapse_root=Node3D.new();collapse_root.name="VisibleSnowSlide";add_child(collapse_root)
	var origin=route.POINTS[12]
	for i in 12:
		var node=make_rock(origin+Vector3(8+float(i%3)*1.4,5+float(i/3)*1.8,-4-float(i%4)),rng.randf_range(.65,1.4),false)
		debris.append({"node":node,"from":node.position,"to":origin+Vector3(-.9+float(i%3)*1.1,-.1,-4-float(i/3)*1.5)})
	collapse_blocker=StaticBody3D.new();collapse_blocker.collision_layer=0;add_child(collapse_blocker);collapse_blocker.position=origin+Vector3(0,1.5,-4.0)
	var shape=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3(5.4,4.8,8);collapse_blocker.add_child(shape)
	var drift_point=route.POINTS[14];detour_drift=make_rock(drift_point,1.6,true);detour_drift.material_override=snow_material;drift_origin=detour_drift.position
	slide_cloud=GPUParticles3D.new();add_child(slide_cloud);slide_cloud.position=origin+Vector3(5,3,-3);slide_cloud.amount=150;slide_cloud.lifetime=3;slide_cloud.one_shot=true;slide_cloud.explosiveness=.65;slide_cloud.emitting=false;slide_cloud.visibility_aabb=AABB(Vector3(-25,-12,-18),Vector3(50,30,36))
	var process=ParticleProcessMaterial.new();process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX;process.emission_box_extents=Vector3(2,1,3);process.direction=Vector3(-1,-.35,0);process.spread=20;process.initial_velocity_min=4;process.initial_velocity_max=9;process.gravity=Vector3(0,-2,0);process.scale_min=.45;process.scale_max=1.5;slide_cloud.process_material=process
	var mesh=QuadMesh.new();mesh.size=Vector2.ONE;var mat=StandardMaterial3D.new();mat.albedo_color=Color(.73,.81,.87,.35);mat.albedo_texture=load("res://assets/snow/snow_cloud.png");mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mesh.material=mat;slide_cloud.draw_pass_1=mesh;slide_cloud.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func begin_collapse():
	if collapse_active or collapse_time>0:return
	collapse_active=true;collapse_time=0;slide_cloud.set_meta("fired",false)
func set_collapsed(value:bool):
	collapse_active=false;collapse_time=8 if value else 0;collapse_blocker.collision_layer=1 if value else 0
	for row in debris:row.node.position=row.to if value else row.from
	if detour_drift:
		detour_drift.position=drift_origin+Vector3(-7,-4,1) if value else drift_origin
		for child in detour_drift.get_children():
			if child is StaticBody3D:child.collision_layer=0 if value else 1
	if slide_cloud:slide_cloud.emitting=false
func tick(delta:float):
	if not mission or mission.paused:return
	if collapse_active:
		collapse_time+=delta
		if collapse_time<3.5:mission.view.shake=maxf(mission.view.shake,.23)
		if collapse_time>1.6 and not slide_cloud.get_meta("fired",false):slide_cloud.restart();slide_cloud.set_meta("fired",true)
		var drift_t=smoothstep(2.4,4.0,collapse_time);detour_drift.position=drift_origin+Vector3(-7,-4,1)*drift_t
		if drift_t>0:
			for child in detour_drift.get_children():
				if child is StaticBody3D:child.collision_layer=0
		for i in debris.size():
			var row=debris[i];var t=clampf((collapse_time-1.6-float(i)*.07)/2.0,0,1)
			row.node.position=Vector3(row.from).lerp(row.to,smoothstep(0,1,t));row.node.rotation.z=t*2.0
		if collapse_time>3.2:collapse_blocker.collision_layer=1
		if collapse_time>6:collapse_active=false
	if mission.player:_footprints().track(mission.player)
	if snow_powder and mission.player:
		snow_powder.position=mission.player.position+Vector3.UP*.08;snow_powder.emitting=mission.player.position.y>24 and mission.player.velocity.length()>1 and mission.player.is_on_floor()
func _powder():
	snow_powder=GPUParticles3D.new();add_child(snow_powder);snow_powder.amount=16;snow_powder.lifetime=.45
	var process=ParticleProcessMaterial.new();process.direction=Vector3.UP;process.spread=65;process.initial_velocity_min=.3;process.initial_velocity_max=.8;process.gravity=Vector3(0,-1,0);process.scale_min=.025;process.scale_max=.065;snow_powder.process_material=process
	var mesh=SphereMesh.new();mesh.radius=.08;mesh.height=.16;mesh.radial_segments=6;mesh.rings=3;mesh.material=material(Color("cedce6"));snow_powder.draw_pass_1=mesh;snow_powder.emitting=false

func _footprints():
	if not is_instance_valid(footprints):
		footprints=load("res://game/memorial/footprints.gd").new();footprints.world=self;add_child(footprints)
	return footprints
