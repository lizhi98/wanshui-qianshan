extends "res://game/snow/weather.gd"
func tick(delta:float):
	super.tick(delta)
	if not mission.started or mission.paused:return
	if mission.stage in ["SEARCH","DISCOVERY","SALUTE"]:
		gust*=.4;exposure=gust*shelter_factor(mission.player.position)
		flakes.amount_ratio*=.45;mist.amount_ratio*=.5
		mission.world.environment.fog_density=.0025
	if mission.stage=="CONTINUE":
		gust*=.65;exposure=gust*shelter_factor(mission.player.position);mission.world.environment.fog_density=.0018
