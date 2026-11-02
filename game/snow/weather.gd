extends Node3D
var mission
var clock:=0.0
var gust:=0.0
var exposure:=0.0
var strength:=0.0
var sheltered:=false
var flakes:GPUParticles3D
var mist:GPUParticles3D
var shelter_visits:Dictionary={}
func setup(m):
	mission=m
	flakes=_snow(950,.035,5.0,Color("e3edf4"));flakes.name="DirectionalSnowfall"
	mist=_snow(85,.55,2.8,Color(.75,.82,.88,.09));mist.name="BlowingSnowVeil"
func _snow(amount:int,size_value:float,life:float,color:Color)->GPUParticles3D:
	var node=GPUParticles3D.new();add_child(node);node.amount=amount;node.lifetime=life;node.preprocess=life*.5;node.visibility_aabb=AABB(Vector3(-35,-12,-35),Vector3(70,50,70))
	var process=ParticleProcessMaterial.new();process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX;process.emission_box_extents=Vector3(18,9,18);process.direction=Vector3(-1,-.35,.5);process.spread=12;process.initial_velocity_min=4;process.initial_velocity_max=8;process.gravity=Vector3(0,-.6,0);node.process_material=process
	var mesh=QuadMesh.new();mesh.size=Vector2.ONE*size_value
	var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;mesh.material=mat
	mat.albedo_texture=load("res://assets/snow/snow_cloud.png")
	node.draw_pass_1=mesh;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;return node
func tick(delta:float):
	if not mission.started:return
	for node in [flakes,mist]:node.speed_scale=0 if mission.paused else 1
	if mission.paused:return
	clock+=delta
	var p=mission.player.position;var near=mission.world.route.nearest(p)
	strength=smoothstep(14,40,p.y)
	var wind_zone=(near.s>mission.world.route.lengths[6] and near.s<mission.world.route.lengths[10]+4) or near.s>mission.world.route.lengths[20]
	gust=(.12+pow((sin(clock*TAU/10.5)+1)*.5,2)*.88)*strength if wind_zone else strength*.12
	sheltered=shelter_factor(p)<.5;exposure=gust*shelter_factor(p)
	for i in mission.world.shelter_centers.size():
		if p.distance_to(mission.world.shelter_centers[i])<3.5:shelter_visits[str(i)]=true
	position=p+Vector3(0,5,0)
	flakes.amount_ratio=clampf(.04+strength*.55+gust*.35,.02,.95);mist.amount_ratio=gust*.6
	for node in [flakes,mist]:
		var process:ParticleProcessMaterial=node.process_material;process.direction=Vector3(-1,-.28,.5);process.initial_velocity_min=3+gust*7;process.initial_velocity_max=5+gust*10
	mission.world.environment.fog_density=.0018+strength*.0012+gust*.0025
	mission.world.environment.volumetric_fog_density=.0009+gust*.0015
	if mission.audio:mission.audio.wind.volume_db=-34+strength*9+gust*7
func shelter_factor(p:Vector3)->float:
	for point in mission.world.shelter_centers:
		if Vector2(p.x-point.x,p.z-point.z).length()<3.6 and absf(p.y-point.y)<3:return .12
	return 1.0
func force_at(p:Vector3)->Vector3:return Vector3(-1.65,0,.85)*gust*shelter_factor(p)
