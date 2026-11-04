extends SceneTree
var failures := 0
var checks := 0
func _initialize(): call_deferred("run")
func check(value:bool,label:String):
	checks+=1
	print(("PASS " if value else "FAIL ")+label)
	if not value: failures+=1
func advance_until(f, wanted, limit:=12.0):
	var elapsed=0.0
	while f.state!=wanted and elapsed<limit:
		f.tick(1.0/60.0,false); elapsed+=1.0/60.0
	return elapsed
func hooked(f):
	f.prepare(); f.cast(.62,true)
	advance_until(f,f.State.BITE)
	check(f.strike(),"visible bite accepts a timely strike")
	advance_until(f,f.State.REELING)
func run():
	check(FileAccess.file_exists("res://game/golden_hook/fishing_model.gd"),"fishing rules module exists")
	if failures: quit(1); return
	var script=load("res://game/golden_hook/fishing_model.gd")
	var f=script.new()
	f.set_seed(27)
	f.prepare(); check(f.state==f.State.PREPARE,"prepare enters controllable holding state")
	check(not f.cast(.7,false) and f.state==f.State.ESCAPED,"cast outside pond cannot award fish")
	f.prepare(); check(f.cast(.6,true),"valid-water cast begins ballistic phase")
	check(not f.strike() and f.state==f.State.CASTING,"strike cannot skip the casting flight")
	advance_until(f,f.State.WAITING)
	check(not f.strike() and f.state==f.State.ESCAPED,"early strike has immediate recoverable feedback")
	f.prepare(); f.cast(.6,true)
	var wait=advance_until(f,f.State.BITE)
	check(wait>=2.4 and wait<=6.1,"fish always gives a bounded observable waiting interval")
	check(f.bite_window>=.8 and f.bite_window<=1.2,"default bite window is within requested range")
	f.tick(f.bite_window+.02,false)
	check(f.state==f.State.ESCAPED,"late strike misses the explicit reaction window")
	f.prepare(); check(f.state==f.State.PREPARE,"escape retries immediately without a walk or cooldown")
	f.bite_window=1.2; f.cast(.6,true); advance_until(f,f.State.BITE); f.tick(1.1,false)
	check(f.strike(),"adjusted reaction window is honored")
	f.cancel(); check(f.state==f.State.INACTIVE,"cancel exits all fishing control")
	hooked(f)
	var initial_progress=f.progress
	for i in 240: f.tick(1.0/60.0,false)
	check(f.state==f.State.ESCAPED and f.progress<=initial_progress,"no-input waiting never grants a fish and slack can escape")
	hooked(f)
	for i in 360: f.tick(1.0/60.0,true)
	check(f.state==f.State.ESCAPED,"holding continuously creates an overtension failure")
	var durations=[]
	for seed_value in 20:
		f=script.new(); f.set_seed(seed_value); hooked(f)
		var elapsed=0.0
		var hold=true
		while f.state==f.State.REELING and elapsed<25:
			if f.tension>.68: hold=false
			elif f.tension<.36: hold=true
			f.tick(1.0/60.0,hold); elapsed+=1.0/60.0
		check(f.state==f.State.CAUGHT,"observed-tension inputs catch fish for seed %d"%seed_value)
		check(elapsed>=8 and elapsed<=20,"reeling takes 8–20 seconds for seed %d (%.2fs)"%[seed_value,elapsed])
		var once=f.catch_serial
		for i in 240: f.tick(1.0/60.0,true)
		check(f.catch_serial==once,"caught state cannot duplicate rewards")
		durations.append(elapsed)
	print("FISHING_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"durations":durations}))
	quit(1 if failures else 0)
