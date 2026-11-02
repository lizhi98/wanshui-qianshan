extends "res://game/v33/foliage.gd"
func setup(m):
	mission=m;rng.seed=440612
	vegetation_material=ShaderMaterial.new();vegetation_material.shader=load("res://game/v33/foliage.gdshader")
	var grass_points=[];var bush_points=[];var ferns=[]
	for i in 1450:
		var p=mission.world.route.at(rng.randf_range(0,mission.world.route.lengths[6]))
		var side=mission.world.route.nearest(p).tangent.cross(Vector3.UP);p+=side*rng.randf_range(3.5,18)*(-1 if i%2 else 1);p.y=mission.world.height_at(p)
		if p.y>30:continue
		var plant_transform=Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(.5,1)),p)
		grass_points.append(plant_transform)
		if i%17==0:bush_points.append(plant_transform)
		if i%13==0:ferns.append(plant_transform)
	_instances("FoothillMeadow",_grass_mesh(1),grass_points,vegetation_material,110)
	_instances("FoothillShrubs",_bush_mesh(),bush_points,vegetation_material,130)
	_instances("FoothillFerns",_fern_mesh(),ferns,vegetation_material,90)
	set_quality(mission.high_quality)
