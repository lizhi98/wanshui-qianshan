extends Node3D
const P=preload("res://game/golden_hook/props.gd")
const Fish=preload("res://game/golden_hook/fish.gd")
const PONDS=[Vector3(14,0,-2),Vector3(14,0,-40)]
const RADII=[Vector2(6.5,8),Vector2(6.2,7)]
const BANKS=[Vector3(6.4,0,-2),Vector3(6.7,0,-40)]
const CAMP=Vector3(-8,0,10)
const LAST_CAMP=Vector3(-2,0,-34)
var mission
var sun:DirectionalLight3D
var environment:WorldEnvironment
var points:Dictionary={}
var items:Dictionary={}
var swimmers:Array=[]
var water_materials:Array=[]
var flame:Node3D
var final_flame:Node3D
var pot:Node3D
var pot_fish:Node3D
var pot_greens:Node3D
var steam:GPUParticles3D
var work_parts:Node3D
var work_needle:Node3D
var work_hook:Node3D
var work_thread:Node3D
var thread_progress:=0.0
var work_rod:Node3D
var hook_ground:Node3D
var fire_light:OmniLight3D
var clock:=0.0
var final_weather:=false
var droplets:Array=[]
var distant_column:Array=[]
var leaping_fish:Node3D
var leap_left:=0.0
var grass_batch:MultiMeshInstance3D
var pot_steam:Array=[]
var elder_support:Node3D
var personal_pouch:Node3D
func _ready():
	_lighting(); _terrain(); _ponds(); _plants(); _hills(); _camp(); _points(); _distant_marchers()
func _ellipse(p:Vector3,c:Vector3,r:Vector2)->float:
	var q=Vector2((p.x-c.x)/r.x,(p.z-c.z)/r.y)
	return q.length()/_shore_radius(atan2(q.y,q.x))
func _shore_radius(a:float)->float:
	return 1.0+sin(a*3+.30)*.09+cos(a*7)*.055+sin(a*11-.6)*.025

func height_at(p:Vector3)->float:
	var y=sin(p.x*.105)*.28+cos(p.z*.085)*.22+sin(p.x*.235+p.z*.17)*.075+sin(p.x*.075+p.z*.05)*.65
	y*=lerpf(.38,1.0,smoothstep(3,12,p.distance_to(CAMP)))
	for i in 2:
		var d=_ellipse(p,PONDS[i],RADII[i])
		if d<1.0: y=-.22-pow(1.0-d,.75)*.78
		elif d<1.45:y=lerpf(-.22,minf(y,.20),smoothstep(1.0,1.45,d))
		elif d<1.9:y=lerpf(minf(y,.20),y,smoothstep(1.45,1.9,d))
	return y

func surface_at(p:Vector3)->String:
	if _ellipse(p,Vector3(-10,0,-24),Vector2(4.2,5.7))<1: return "swamp"
	if _ellipse(p,Vector3(-1,0,-14),Vector2(3.7,2.6))<1: return "shallow"
	if _ellipse(p,Vector3(2,0,1),Vector2(5.2,4.0))<1: return "mud"
	return "grass"
func valid_water(p:Vector3,pond:int)->bool:
	return pond in [0,1] and _ellipse(p,PONDS[pond],RADII[pond])<.91
func at_ground(p:Vector3)->Vector3:
	return Vector3(p.x,height_at(p),p.z)
func _lighting():
	environment=WorldEnvironment.new(); add_child(environment)
	var env=Environment.new(); environment.environment=env
	env.background_mode=Environment.BG_SKY
	var sky=Sky.new();var material=PanoramaSkyMaterial.new();material.panorama=load("res://assets/golden_hook/environment/overcast_sky.hdr");sky.sky_material=material;env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("a4b4b1"); env.ambient_light_energy=.5
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.fog_enabled=true; env.fog_light_color=Color("7d9693"); env.fog_density=.0025; env.fog_sky_affect=.35
	env.ssao_enabled=true; env.ssao_intensity=1.3
	env.ssr_enabled=true; env.ssr_max_steps=32
	env.glow_enabled=true; env.glow_intensity=.3
	sun=DirectionalLight3D.new(); add_child(sun); sun.rotation_degrees=Vector3(-24,-48,0)
	sun.light_color=Color("d8dfd8"); sun.light_energy=.85; sun.shadow_enabled=true; sun.directional_shadow_max_distance=65
func _terrain():
	var st=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in 110:
		for ix in 100:
			var x=-50+ix; var z=-70+iz
			for v in [at_ground(Vector3(x,0,z)),at_ground(Vector3(x+1,0,z)),at_ground(Vector3(x,0,z+1)),at_ground(Vector3(x+1,0,z)),at_ground(Vector3(x+1,0,z+1)),at_ground(Vector3(x,0,z+1))]: st.add_vertex(v)
	st.generate_normals(); st.index(); var ground=st.commit()
	var m=ShaderMaterial.new(); m.shader=load("res://game/golden_hook/ground.gdshader")
	for pair in [["ground_tex","aerial_grass_rock_Diffuse"],["ground_normal","aerial_grass_rock_nor_gl"],["mud_tex","brown_mud_02_Diffuse"],["mud_normal","brown_mud_02_nor_gl"],["mud_orm","brown_mud_02_arm"]]: m.set_shader_parameter(pair[0],load("res://assets/golden_hook/environment/pbr/"+pair[1]+".jpg"))
	P.mesh(self,ground,Vector3.ZERO,m).name="NearTerrainMesh"
	# Concentric rings retain every one-metre edge vertex. A coarse rectangular
	# grid interpolated over these edges left thin holes against the finer mesh.
	var border:Array[Vector3]=[]
	for x in range(-50,50):border.append(Vector3(x,0,-70))
	for z in range(-70,40):border.append(Vector3(50,0,z))
	for x in range(50,-50,-1):border.append(Vector3(x,0,40))
	for z in range(40,-70,-1):border.append(Vector3(-50,0,z))
	var distant=SurfaceTool.new();distant.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in 24:
		for i in border.size():
			var j=(i+1)%border.size()
			var a=_distant_point(border[i],ring);var b=_distant_point(border[j],ring)
			var c=_distant_point(border[i],ring+1);var d=_distant_point(border[j],ring+1)
			for v in [a,c,b,b,c,d]:distant.add_vertex(v)
	distant.generate_normals();distant.index();P.mesh(self,distant.commit(),Vector3.ZERO,m).name="DistantTerrainMesh"
	var body=StaticBody3D.new(); body.name="WetlandCollision"; add_child(body)
	var cs=CollisionShape3D.new(); cs.shape=ground.create_trimesh_shape(); body.add_child(cs)
	_patch(Vector3(-10,0,-24),Vector2(4.2,5.7),"252b21",.24)
	_patch(Vector3(-1,0,-14),Vector2(3.7,2.6),"54624c",.23)
	for pair in [[Vector3(-45,1,-16),Vector3(.4,3,106)],[Vector3(45,1,-16),Vector3(.4,3,106)],[Vector3(0,1,-68),Vector3(90,3,.4)],[Vector3(0,1,36),Vector3(90,3,.4)]]: _wall(pair[0],pair[1])

func _distant_point(border:Vector3,ring:int)->Vector3:
	var factor=1.0+float(ring)/24.0*5.4
	var p=Vector3(border.x*factor,0,(border.z+15)*factor-15)
	var edge=maxf(absf(p.x)-50,maxf(-70-p.z,p.z-40));var rise=smoothstep(0,85,edge)
	p.y=height_at(p)+rise*(12.0+sin(p.x*.018+p.z*.014)*7.0+sin(p.z*.024)*5.0)
	return p

func _patch(center:Vector3,radius:Vector2,color:String,rough:float):
	var st=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c=at_ground(center)+Vector3(0,.018,0)
	for i in 48:
		var a=i*TAU/48; var b=(i+1)*TAU/48
		var ra=1+sin(a*5)*.08+cos(a*3)*.05; var rb=1+sin(b*5)*.08+cos(b*3)*.05
		var p=at_ground(center+Vector3(cos(a)*radius.x*ra,0,sin(a)*radius.y*ra))+Vector3(0,.022,0)
		var q=at_ground(center+Vector3(cos(b)*radius.x*rb,0,sin(b)*radius.y*rb))+Vector3(0,.022,0)
		for v in [c,p,q]: st.add_vertex(v)
	st.generate_normals(); P.mesh(self,st.commit(),Vector3.ZERO,P.mat(color,rough))
func _wall(center:Vector3,size:Vector3):
	var body=StaticBody3D.new(); add_child(body); body.position=center
	var cs=CollisionShape3D.new(); var shape=BoxShape3D.new(); shape.size=size; cs.shape=shape; body.add_child(cs)
func _ponds():
	for i in 2:
		var center=PONDS[i]; var radius=RADII[i]
		var st=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in 64:
			var a=j*TAU/64; var b=(j+1)*TAU/64
			var r=_shore_radius(a); var s=_shore_radius(b)
			for v in [Vector3(0,-.17,0),Vector3(cos(b)*radius.x*s,-.17,sin(b)*radius.y*s),Vector3(cos(a)*radius.x*r,-.17,sin(a)*radius.y*r)]: st.add_vertex(v)
		st.generate_normals(); var material=ShaderMaterial.new(); material.shader=load("res://game/golden_hook/water.gdshader")
		water_materials.append(material); P.mesh(self,st.commit(),center,material)
		# Deep-water ring collision follows the bank, with an explicit natural shore.
		for j in 40:
			var a=j*TAU/40
			var pos=center+Vector3(cos(a)*radius.x*_shore_radius(a)*.95,-.1,sin(a)*radius.y*_shore_radius(a)*.95)
			var body=StaticBody3D.new(); add_child(body); body.position=pos
			var cs=CollisionShape3D.new(); var shape=CapsuleShape3D.new(); shape.radius=.58; shape.height=2.3; cs.shape=shape; body.add_child(cs)
		for j in 5:
			var fish=Fish.new(); fish.shadow=true; add_child(fish)
			swimmers.append({"node":fish,"pond":i,"phase":j*1.7,"radius":1.8+j*.5})
func _plants():
	var habitat=load("res://game/golden_hook/habitat.gd").new();habitat.world=self;add_child(habitat)
	grass_batch=habitat.far_grass
	var reeds=load("res://assets/golden_hook/models/marsh_reeds.glb").instantiate()
	var source_meshes=reeds.find_children("*","MeshInstance3D",true,false)
	var rng=RandomNumberGenerator.new();rng.seed=193508
	for pond in 2:
		var transforms=[]
		for cluster in 12:
			var a=cluster*TAU/12+rng.randf_range(-.12,.12)
			if absf(angle_difference(a,PI))<.42:continue
			for tuft in 4:
				var angle=a+rng.randf_range(-.12,.12);var radius=_shore_radius(angle)*rng.randf_range(1.04,1.13)
				var pos=PONDS[pond]+Vector3(cos(angle)*RADII[pond].x*radius,0,sin(angle)*RADII[pond].y*radius)
				transforms.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(.72,1.05)),at_ground(pos)))
		for source in source_meshes:
			var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=source.mesh;mm.instance_count=transforms.size()
			for i in transforms.size():mm.set_instance_transform(i,transforms[i]*source.transform)
			var n=MultiMeshInstance3D.new();n.multimesh=mm;add_child(n);n.visibility_range_end=65;n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	reeds.free()

func _hills():
	var rng=RandomNumberGenerator.new();rng.seed=193511
	var source=load("res://assets/golden_hook/environment/rock_moss_set_01.glb").instantiate()
	var meshes=source.find_children("*","MeshInstance3D",true,false)
	for i in 22:
		var pos=Vector3(rng.randf_range(-39,36),0,rng.randf_range(-61,28))
		if i<5:pos=[Vector3(-17,0,-8),Vector3(-16,0,-6),Vector3(-3,0,-34),Vector3(4,0,-49),Vector3(22,0,6)][i]
		if _ellipse(pos,PONDS[0],RADII[0])<1.25 or _ellipse(pos,PONDS[1],RADII[1])<1.25:continue
		var mesh=meshes[i%meshes.size()];var n=MeshInstance3D.new();n.mesh=mesh.mesh;add_child(n)
		var bounds=n.mesh.get_aabb();var fit=(.7 if i<5 else rng.randf_range(.7,1.5))/maxf(bounds.size.x,bounds.size.z)
		n.scale=Vector3.ONE*fit;n.rotation.y=rng.randf()*TAU;n.position=at_ground(pos)-n.basis*Vector3(bounds.get_center().x,bounds.position.y+.04/fit,bounds.get_center().z)
		n.visibility_range_end=90
	source.free()

func _camp():
	P.tent(self,at_ground(Vector3(-15,0,17)))
	for p in [Vector3(-12,0,14.4),Vector3(-4.6,0,13),Vector3(-1.8,0,-34.0)]:P.camp_model(self,"camp_satchel",at_ground(p))
	for p in [Vector3(-10.4,0,12.4),Vector3(-5.2,0,13.7)]:P.camp_model(self,"bedroll",at_ground(p))
	personal_pouch=P.camp_model(self,"camp_satchel",at_ground(Vector3(2,0,-36.6)));personal_pouch.scale=Vector3(.65,.47,.65)
	elder_support=P.camp_model(self,"bedroll",Vector3.ZERO);elder_support.scale=Vector3(.7,.25,.7);elder_support.hide()
	for p in [Vector3(-11,0,10.8),Vector3(-5.5,0,12)]:
		var bed=P.box(self,Vector3(.85,.055,1.9),at_ground(p)+Vector3(0,.03,0),"5b5b43")
		bed.rotation.y=.3
	for p in [Vector3(-10.5,0,10.45),Vector3(-5.6,0,11.55),Vector3(-17,0,-7.25)]:
		P.ellipsoid(self,Vector3(.72,.49,.65),at_ground(p)+Vector3(0,.2,0),"565c4b")
	items.bag_a=P.sack(self,at_ground(Vector3(-12,0,12)))
	items.bag_b=P.sack(self,at_ground(Vector3(-13,0,10.5)))
	items.greens_a=P.greens(self,at_ground(Vector3(-15,0,5)))
	items.greens_b=P.greens(self,at_ground(Vector3(-3,0,3)))
	items.ration=P.bowl(self,false); items.ration.position=at_ground(Vector3(-10,0,9))
	for i in 7: P.ellipsoid(items.ration,Vector3(.008,.005,.012),Vector3(sin(i)*.05,.02,cos(i)*.05),"c6b98d")
	items.needle=Node3D.new(); add_child(items.needle); items.needle.position=at_ground(Vector3(-9,0,11))
	P.box(items.needle,Vector3(.34,.06,.24),Vector3(0,.04,0),"574b3f")
	items.thread=Node3D.new(); add_child(items.thread); items.thread.position=at_ground(Vector3(-5,0,10))
	P.cylinder(items.thread,Vector3(0,.05,0),Vector3(0,.23,0),.07,P.mat("b3a88b"))
	items.branch=Node3D.new(); add_child(items.branch); items.branch.position=at_ground(Vector3(-1,0,5))
	P.cylinder(items.branch,Vector3(-.8,.05,0),Vector3(.8,.12,.12),.024,P.mat("69573b"))
	flame=_fire(Vector3(-7,0,7.6)); final_flame=_fire(Vector3(-.8,0,-34.5)); final_flame.hide()
	pot=_pot(Vector3(-7,0,7.6)); pot_fish=Node3D.new(); pot.add_child(pot_fish); pot_fish.position=Vector3(0,.39,0); pot_fish.hide()
	for i in 2:
		var fish=Fish.new(); pot_fish.add_child(fish); fish.position=Vector3((i-.5)*.15,0,0); fish.rotation.y=i*1.6
	pot_greens=P.greens(pot,Vector3(0,.42,0)); pot_greens.scale=Vector3.ONE*.6; pot_greens.hide()
	var final_pot=_pot(Vector3(-.8,0,-34.5))
	work_parts=Node3D.new(); add_child(work_parts); work_parts.position=at_ground(Vector3(-8.4,0,7.8))+Vector3(0,.05,0)
	P.box(work_parts,Vector3(.72,.06,.46),Vector3.ZERO,"81775e")
	work_hook=P.hook(work_parts); work_hook.position=Vector3(0,.06,0); work_hook.scale=Vector3.ONE*1.25; work_hook.rotation.z=PI/2; work_hook.hide()
	work_thread=MeshInstance3D.new();work_parts.add_child(work_thread);work_thread.material_override=P.mat("c3b99e");work_thread.hide()
	work_rod=P.cylinder(work_parts,Vector3(-.8,.045,.18),Vector3(.8,.05,.18),.018,P.mat("6c5738")); work_rod.hide()
	work_needle=work_hook
	hook_ground=work_hook
	work_hook.set_meta("hook_id","grassland_needle_01")
func _fire(p:Vector3)->Node3D:
	var n=Node3D.new(); add_child(n); n.position=at_ground(p)
	for i in 6:
		var a=i*TAU/6
		P.ellipsoid(n,Vector3(.27,.13,.21),Vector3(sin(a)*.43,.06,cos(a)*.43),"5b6150")
		P.cylinder(n,Vector3(sin(a)*.33,.10,cos(a)*.33),Vector3(-sin(a)*.21,.19,-cos(a)*.21),.036,P.mat("51402d"))
	var fire=Node3D.new(); fire.name="Flames"; n.add_child(fire)
	for i in 4:
		var m=ShaderMaterial.new(); m.shader=load("res://game/golden_hook/flame.gdshader"); m.set_shader_parameter("phase",i*1.7)
		var shape=QuadMesh.new(); shape.size=Vector2(.22,.43)
		var f=P.mesh(fire,shape,Vector3(sin(i)*.075,.30,cos(i)*.075),m); f.rotation.y=i*PI*.37
	var light=OmniLight3D.new(); fire.add_child(light); light.position.y=.6; light.light_color=Color("ffb878"); light.light_energy=.72; light.omni_range=4
	return n
func _pot(p:Vector3)->Node3D:
	var n=Node3D.new(); add_child(n); n.position=at_ground(p)
	var cauldron=load("res://assets/golden_hook/environment/pot_enamel_01.glb").instantiate();n.add_child(cauldron)
	var bounds=AABB();var first=true
	for mesh in cauldron.find_children("*","MeshInstance3D",true,false):
		if "lid" in str(mesh.name).to_lower():mesh.hide();continue
		var box=mesh.transform*mesh.get_aabb();bounds=box if first else bounds.merge(box);first=false
	var fit=.62/maxf(bounds.size.x,bounds.size.z);cauldron.scale=Vector3.ONE*fit;cauldron.position=Vector3(-bounds.get_center().x*fit,.28-bounds.position.y*fit,-bounds.get_center().z*fit)
	var soup=CylinderMesh.new();soup.top_radius=.235;soup.bottom_radius=.235;soup.height=.006;P.mesh(n,soup,Vector3(0,.48,0),P.mat("8d8a5c",.25))
	for x in [-.42,.42]: P.cylinder(n,Vector3(x,0,0),Vector3(x*.6,.8,0),.025,P.mat("534730"))
	P.cylinder(n,Vector3(-.28,.8,0),Vector3(.28,.8,0),.025,P.mat("534730"))
	var vapour=CPUParticles3D.new(); vapour.name="Steam"; n.add_child(vapour); vapour.position.y=.57; vapour.amount=12; vapour.lifetime=2.4; vapour.direction=Vector3.UP; vapour.spread=9; vapour.gravity=Vector3(0,.015,0); vapour.initial_velocity_min=.12; vapour.initial_velocity_max=.22
	vapour.scale_amount_min=.16; vapour.scale_amount_max=.26; var puff=QuadMesh.new(); puff.size=Vector2(.35,.35); vapour.mesh=puff
	var soft=ShaderMaterial.new(); soft.shader=load("res://game/golden_hook/steam.gdshader"); vapour.material_override=soft; vapour.emitting=false; pot_steam.append(vapour)
	var fade=Gradient.new(); fade.set_color(0,Color(1,1,1,0)); fade.set_color(1,Color(1,1,1,0)); fade.add_point(.25,Color(1,1,1,.8)); vapour.color_ramp=fade
	return n
func _points():
	for id in items: points[id]=items[id].position
	points.merge({"comrade_a":Vector3(-10.5,0,10.7),"comrade_b":Vector3(-5.6,0,11.8),"elder":Vector3(-8.4,0,7),"work":Vector3(-8.4,0,7.8),"pot":Vector3(-7,0,7.6),"first_bank":BANKS[0],"secret":Vector3(-17,0,-7),"last_elder":Vector3(2,0,-36),"last_bank":BANKS[1],"last_pot":Vector3(-.8,0,-34.5),"hook":Vector3(2,0,-36.6),"exit":Vector3(-3,0,-57)})
	for id in points: points[id]=at_ground(points[id])
func _distant_marchers():
	for i in 6:
		var n=load("res://game/golden_hook/npc.gd").new(); n.name="Distant_Zhou_"+str(i) if i%3==0 else "Distant_RedArmy_"+str(i)
		n.mission=mission; n.visual_type=load("res://game/golden_hook/character.gd"); n.position=at_ground(Vector3(-30,0,25-i*3.1)); add_child(n)
		n.visual.posture="weak"; n.collision_layer=0
		n.walk([at_ground(Vector3(-30,0,-60)),at_ground(Vector3(-35,0,-60)),at_ground(Vector3(-35,0,29)),at_ground(Vector3(-30,0,29))],.8)
		distant_column.append(n)
	leaping_fish=Fish.new(); add_child(leaping_fish); leaping_fish.hide()
func fish_leap():
	leap_left=1.1; leaping_fish.show(); splash(PONDS[0]+Vector3(-1,-.15,0))
func update_story(s):
	for id in ["greens_a","greens_b","needle","thread","branch"]: items[id].visible=not s.done.get(id,false)
	if s.hook_form<4:
		var target=items.needle if not s.done.get("needle",false) else work_parts
		if work_hook.get_parent()!=target:work_hook.reparent(target,false)
		if not mission.crafting:work_hook.position=Vector3(0,.085,0) if target==items.needle else Vector3(0,.10,0)
		work_hook.rotation=Vector3(0,0,PI/2);work_hook.scale=Vector3.ONE*(1.0 if target==items.needle else 1.25)
		work_hook.set_bend(1.0 if s.hook_form>=2 else 0.0);work_hook.set_heat(.12 if s.hook_form==1 else 0.0);work_hook.set_worn(false)
		work_hook.visible=target==items.needle or s.step in ["heat","bend","tie","mount"]
	elif work_hook.get_parent()==work_parts:
		work_hook.reparent(self,true);work_hook.scale=Vector3.ONE;work_hook.hide();work_hook.set_heat(0);work_hook.set_bend(1)
	work_thread.visible=s.hook_form==3
	work_rod.visible=s.step in ["heat","bend","tie","mount"]
	pot_fish.visible=s.done.get("put_fish",false) and not s.done.get("finish_soup",false)
	pot_greens.visible=s.done.get("put_greens",false) and not s.done.get("finish_soup",false)
	flame.get_node("Flames").visible=s.step in ["heat","bend","tie","mount"] or s.done.get("light_fire",false)
	final_flame.visible=s.done.get("last_cook",false)
	pot_steam[0].emitting=s.step in ["simmer","serve","secret"]
	pot_steam[1].emitting=s.step in ["last_deliver","farewell","keepsake"]
	if s.step=="keepsake":
		if hook_ground.get_parent()!=self: hook_ground.reparent(self,true)
		hook_ground.global_position=points.hook+Vector3(0,.17,0); hook_ground.rotation=Vector3(0,0,PI/2); hook_ground.scale=Vector3.ONE*1.5; hook_ground.show()
		hook_ground.set_worn(true)

func set_final_weather(value:bool):
	final_weather=value
	sun.light_energy=.58 if value else .85
	sun.light_color=Color("bec9c4") if value else Color("d8dfd8")
	sun.rotation_degrees.x=-13 if value else -24
	environment.environment.fog_density=.004 if value else .0025
	environment.environment.background_energy_multiplier=.72 if value else 1.0
	for m in water_materials: m.set_shader_parameter("darkness",1.0 if value else 0.0)
func set_performance_mode(low:bool):
	environment.environment.ssao_enabled=not low; environment.environment.glow_enabled=not low; sun.shadow_enabled=not low
	if grass_batch: grass_batch.multimesh.visible_instance_count=int(grass_batch.multimesh.instance_count*.58) if low else -1
	for i in distant_column.size():
		distant_column[i].visible=not low or i%2==0; distant_column[i].visual.set_process(not low or i%2==0)
	for steam_node in pot_steam: steam_node.visible=not low
func splash(p:Vector3):
	for i in 12:
		var n=P.ellipsoid(self,Vector3(.025,.045,.025),p,"a8beb0")
		droplets.append({"node":n,"v":Vector3(sin(i*2.4)*.6,.6+(i%4)*.12,cos(i*2.4)*.6),"t":0.0})
func _process(delta):
	if mission and mission.paused: return
	clock+=delta
	if work_thread.visible:
		var line=ImmediateMesh.new();line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		var start=work_hook.to_global(Vector3(0,.058,0));var end=work_parts.to_global(Vector3(.80,.05,.18))
		for i in 20:
			var t=i/19.0*thread_progress;line.surface_add_vertex(work_thread.to_local(start.lerp(end,t)-Vector3(0,sin(t*PI)*.025,0)))
		line.surface_end();work_thread.mesh=line
	if mission and is_instance_valid(mission.elder):
		var collapsed=mission.elder.visual.posture=="collapsed"
		personal_pouch.visible=collapsed or mission.story.step in ["keepsake","leave","archive"]
		elder_support.visible=collapsed and mission.elder.visual.collapse_clock>1.5
		if elder_support.visible:
			var sk=mission.elder.visual.skeleton;var head=sk.to_global(sk.get_bone_global_pose(sk.find_bone("Head")).origin)
			elder_support.position=at_ground(head);elder_support.rotation.y=mission.elder.rotation.y

	for n in distant_column:
		if not n.moving: n.walk([at_ground(Vector3(-30,0,-60)),at_ground(Vector3(-35,0,-60)),at_ground(Vector3(-35,0,29)),at_ground(Vector3(-30,0,29))],.8)
	if leap_left>0:
		leap_left=maxf(0,leap_left-delta); var t=1-leap_left/1.1
		leaping_fish.position=PONDS[0]+Vector3(-1+t*1.2,-.30+sin(t*PI)*.65,0); leaping_fish.rotation.z=sin(t*PI)*.65
		if leap_left<=0: splash(leaping_fish.position); leaping_fish.hide()
	for entry in swimmers:
		var t=clock*.35+entry.phase; var c=PONDS[entry.pond]
		entry.node.position=c+Vector3(sin(t)*entry.radius,-.39+sin(t*2)*.03,cos(t)*entry.radius*.7)
		entry.node.rotation.y=atan2(cos(t),-sin(t)*.7)
	for n in [flame,final_flame]:
		if not n: continue
		var f=n.get_node("Flames"); f.scale=Vector3(1+sin(clock*8)*.06,1+sin(clock*11)*.13,1)
	for i in range(droplets.size()-1,-1,-1):
		var d=droplets[i]; d.t+=delta; d.v.y-=delta*2.2; d.node.position+=d.v*delta
		if d.t>1: d.node.queue_free(); droplets.remove_at(i)
