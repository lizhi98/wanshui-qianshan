extends "res://game/snow/world.gd"
const Props=preload("res://game/memorial/props.gd")
const MEMORIAL=Vector3(14,48,-108.4)
const CRATE=Vector3(-5,0,37)
var obstacle_root:Node3D
var parcel_nodes:Array=[]
var obstacle_cleared:=false
var stage_light:=0.0
var memorial_book:Node3D
var memorial_support:MeshInstance3D
var obstacle_origins:Array=[]
func make_rock(point:Vector3,radius:float,solid:=true)->MeshInstance3D:
	# The inherited bend-7 boulder overlaps the outside lane during crowd passing.
	# Move both visible geometry and its convex body; retain real blocking collision.
	if solid and is_equal_approx(radius,2.7):
		var bend=route.POINTS[7]
		var normal=((bend-route.POINTS[6]).normalized().cross(Vector3.UP)+(route.POINTS[8]-bend).normalized().cross(Vector3.UP)).normalized()
		var expected=bend+normal*4.8
		if Vector2(point.x-expected.x,point.z-expected.z).length()<.05:
			point+=normal*2.2;point.y=height_at(point)-.4
			var rock=super.make_rock(point,radius,solid);rock.name="Bend7ClearanceRock";return rock
	return super.make_rock(point,radius,solid)
func _ready():
	route=load("res://game/memorial/route.gd").new()
	super._ready();jump_centers.clear();_camp();_rock_layers();_distant_ring()
	for node in find_children("*","MeshInstance3D",true,false):
		if node.material_override is ShaderMaterial:node.material_override.shader=load("res://game/memorial/terrain.gdshader")
func height_at(p:Vector3)->float:
	var q=route.sample(p);var d=q.z
	var rough=noise.get_noise_2d(p.x,p.z)*5.0+sin(p.x*.031+p.z*.02)*1.4
	var broad=(40-p.z)*119/311.5+absf(p.x)*.055+rough
	var width=2.2+sin(q.w*.07)*.45
	var value=lerpf(broad,q.y,1-smoothstep(width,13,d))
	var camp=Vector2(p.x/21,(p.z-37)/18).length()
	value=lerpf(value,0,1-smoothstep(.75,1.2,camp))
	var a=Vector2(8.4,-104.2);var b=Vector2(MEMORIAL.x,MEMORIAL.z);var v=Vector2(p.x,p.z)
	var t=clampf((v-a).dot(b-a)/(b-a).length_squared(),0,1);var distance=v.distance_to(a.lerp(b,t))
	if distance<6:value=lerpf(value,lerpf(47,48,t),1-smoothstep(2.7,6,distance))
	var alcove=v.distance_to(b)
	if alcove<7:value=lerpf(value,48,1-smoothstep(3.5,7,alcove))
	return value
func _make_clues():
	clues={"stock":{"point":CRATE+Vector3(0,.7,0),"kind":"最后三包御寒衣物"},"wind_mark":{"point":route.POINTS[8]+Vector3(1.1,.4,0),"kind":"岩旁的布条与压实足迹"},"strap":{"point":route.POINTS[13]+Vector3(.6,.15,-1),"kind":"熟悉的褐色挎包扎带"},"coat":{"point":MEMORIAL+Vector3(.19,.38,0),"kind":"湿透的单薄衣袖"},"ledger":{"point":MEMORIAL+Vector3(.25,.55,.10),"kind":"扣着的军需记录"}}
	for key in ["wind_mark","strap"]:
		var point:Vector3=clues[key].point;point.y=height_at(point)+.2;clues[key].point=point
		var n=Node3D.new();add_child(n);n.position=point
		Props.box(n,Vector3(.06,.3,.035),Vector3.ZERO,Color("8b7050") if key=="strap" else Color("ac8e6b"))
	var trace_rng=RandomNumberGenerator.new();trace_rng.seed=4131935
	var forward=(MEMORIAL-route.POINTS[13]).normalized();forward.y=0;forward=forward.normalized();var side=forward.cross(Vector3.UP)
	for j in 24:
		var t=clampf((float(j)+trace_rng.randf_range(-.08,.08))/24,0,1)
		var p=route.POINTS[13].lerp(MEMORIAL,t)+side*((.12 if j%2==0 else -.12)+trace_rng.randf_range(-.035,.035))
		p.y=height_at(p)+.1;_footprints().queue_mark(p,forward.rotated(Vector3.UP,trace_rng.randf_range(-.055,.055)),j%2==0,true)
func _collapse_setup():pass
func set_collapsed(_value:bool):pass
func _camp():
	var camp=Node3D.new();add_child(camp);camp.name="SupplyCamp"
	for i in 4:
		var p=CRATE+Vector3(float(i%2)*.8,0,float(i/2)*.65)
		Props.box(camp,Vector3(.7,.38,.55),p+Vector3(0,.19,0),Color("63553b"))
	for i in 3:
		var parcel=Props.bundle(self);parcel.position=CRATE+Vector3((i-1)*.25,.64,.02);parcel_nodes.append(parcel)
	var book=Props.ledger(self);book.position=CRATE+Vector3(-.8,.38,.2)
	obstacle_root=Node3D.new();add_child(obstacle_root);obstacle_root.name="MarchRoadObstruction"
	var center=route.at(route.lengths[4]-3)
	for i in 3:
		var p=center+Vector3((i-1)*.5,0,0);p.y=height_at(p)
		var rock=make_rock(p,.65,true);rock.reparent(obstacle_root);obstacle_origins.append(rock.position)
	_make_memorial_support()
	memorial_book=Props.ledger(self);memorial_book.position=MEMORIAL+Vector3(-.72,.12,-.36);memorial_book.rotation.y=.35;memorial_book.hide();clues.ledger.point=memorial_book.position+Vector3.UP*.12
func clear_obstacle():
	if obstacle_cleared:return
	obstacle_cleared=true
	for child in obstacle_root.get_children():
		child.position+=Vector3(3,-.4,.3)
		for body in child.get_children():
			if body is StaticBody3D:body.collision_layer=0
func reset_obstacle():
	obstacle_cleared=false
	for i in obstacle_origins.size():
		var child=obstacle_root.get_child(i);child.position=obstacle_origins[i]
		for body in child.get_children():
			if body is StaticBody3D:body.collision_layer=1
func reset_parcels(count:int):
	for i in parcel_nodes.size():parcel_nodes[i].visible=i<count
func _rock_layers():
	for i in 55:
		var p=route.at(rng.randf_range(100,route.total));p+=route.nearest(p).tangent.cross(Vector3.UP)*rng.randf_range(5.2,16)*(-1 if i%2 else 1)
		if route.sample(p).z<4.8 or p.distance_to(MEMORIAL)<8:continue
		p.y=height_at(p)-.2;var rock=make_rock(p,rng.randf_range(.25,1.1),false);rock.scale.y*=rng.randf_range(.4,.85)
func tick(delta:float):
	if mission.paused:return
	if memorial_book:memorial_book.visible=mission.flags.get("inspected",false)
	_footprints().track(mission.player)
	for a in mission.actors():
		if a!=mission.quartermaster and a.position.distance_to(mission.player.position)<13:_footprints().track(a)
	if snow_powder:snow_powder.position=mission.player.position;snow_powder.emitting=mission.player.position.y>25 and mission.player.velocity.length()>1
	var warm=1.0 if mission.stage=="CAMP" else (.35 if mission.stage=="CONTINUE" else 0.0)
	stage_light=lerpf(stage_light,warm,delta*.2);sun.light_color=Color("d4e0ee").lerp(Color("ffe1ac"),stage_light);sun.light_energy=1.15+stage_light*.2

func _build_ground():
	if ResourceLoader.exists("res://assets/memorial/terrain412/ground_mesh.res") and not "--bake-memorial" in OS.get_cmdline_user_args():
		terrain=MeshInstance3D.new();terrain.name="ContinuousMountainCollision";terrain.mesh=load("res://assets/memorial/terrain412/ground_mesh.res");terrain.material_override=snow_material.duplicate();terrain.material_override.set_shader_parameter("path_surface",true);add_child(terrain)
		var body=StaticBody3D.new();terrain.add_child(body);var collider=CollisionShape3D.new();collider.shape=load("res://assets/memorial/terrain412/ground_shape.res");body.add_child(collider)
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
	if "--bake-memorial" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://assets/memorial/terrain412")
		ResourceSaver.save(terrain.mesh,"res://assets/memorial/terrain412/ground_mesh.res");ResourceSaver.save(terrain.mesh.create_trimesh_shape(),"res://assets/memorial/terrain412/ground_shape.res")
	_build_far_ridges()
func _build_walk_ribbon():
	# One authoritative 1m terrain surface for rendering and collision.
	# The former secondary ribbon folded at sharp bends and blocked capsules.
	pass

func _build_far_ridges():
	# Broad continuous heightfields, with edges below the main terrain. This
	# replaces the overlapping small open peak patches that exposed triangles.
	for side in [-1,1]:
		for k in 3:
			var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(0)
			var grid=[];var center=Vector2(side*(210+k*27),-40-k*150)
			for row in 97:
				for col in 97:
					var x=(col-48)*5.0;var z=(48-row)*5.0;var radius=Vector2(x*.86,z).length()
					var edge=maxf(0,1-radius/265.0);var ridge=pow(edge,1.65)*(130+k*19)
					var px=x+center.x;var pz=z+center.y
					var y=(40-pz)*119.0/311.5-43+ridge+noise.get_noise_2d(px*.8,pz*.8)*14*edge
					grid.append(Vector3(px,y,pz))
			for row in 96:
				for col in 96:
					for index in [row*97+col,(row+1)*97+col,row*97+col+1,row*97+col+1,(row+1)*97+col,(row+1)*97+col+1]:
						st.set_uv(Vector2.ZERO);st.add_vertex(grid[index])
			st.index();st.generate_normals();var node=MeshInstance3D.new();node.mesh=st.commit();node.material_override=snow_material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node)

func snow_from_start()->bool:return true

func _distant_ring():
	# Render-only irregular backdrop. Inner edge overlaps existing broad terrain;
	# the outer edge drops below the horizon, rather than ending as a visible wall.
	var vertices=[];var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in 9:
		var radius=225.0+ring*100.0
		for segment in 129:
			var angle=float(segment)*TAU/128
			var x=cos(angle)*radius;var z=-120+sin(angle)*radius
			var ridge=sin(angle*7+.4)*52+sin(angle*13+1.6)*28+noise.get_noise_2d(x*.4,z*.4)*35
			var height=-65+sin(float(ring)/8*PI)*(320+ridge)-pow(float(ring)/8,5)*250
			vertices.append(Vector3(x,height,z))
	for ring in 8:
		for segment in 128:
			for index in [ring*129+segment,(ring+1)*129+segment,ring*129+segment+1,ring*129+segment+1,(ring+1)*129+segment,(ring+1)*129+segment+1]:
				st.set_uv(Vector2.ZERO);st.add_vertex(vertices[index])
	st.index();st.generate_normals();var mesh=MeshInstance3D.new();mesh.name="FoggedMountainHorizon";mesh.mesh=st.commit();mesh.material_override=snow_material;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mesh)


func _make_memorial_support():
	# Fit actual mesh bounds, not a radius that lets the irregular rock engulf the body.
	memorial_support=rock_meshes[0].duplicate();memorial_support.name="MemorialBackSupport";add_child(memorial_support)
	var bounds=memorial_support.get_aabb();memorial_support.transform=Transform3D.IDENTITY
	memorial_support.scale=Vector3(.85,.45,.60)/bounds.size;memorial_support.rotation.y=2.214
	var front=Vector3(sin(2.214),0,cos(2.214))
	memorial_support.position=MEMORIAL-front*.45+Vector3.UP*.015-memorial_support.basis*Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	var mat=snow_material.duplicate();mat.shader=load("res://game/memorial/terrain.gdshader");mat.set_shader_parameter("snow_coverage",.22);memorial_support.material_override=mat
	var body=StaticBody3D.new();body.collision_layer=16;body.collision_mask=0;memorial_support.add_child(body);var collider=CollisionShape3D.new();collider.shape=memorial_support.mesh.create_convex_shape(true,false);body.add_child(collider)
