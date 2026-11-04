extends RefCounted
## Input-driven rules. This module never grants inventory; the chapter consumes
## one caught signal, only while its fishing objective is active.
signal state_changed(value)
signal caught
signal escaped(reason)
enum State { INACTIVE, PREPARE, CASTING, WAITING, BITE, HOOKED, REELING, CAUGHT, ESCAPED }
var state := State.INACTIVE
var bite_window := 1.15
var tension := 0.45
var progress := 0.0
var clock := 0.0
var wait_duration := 3.0
var low_clock := 0.0
var high_clock := 0.0
var catch_serial := 0
var last_reason := ""
var cast_power := 0.0
var rng := RandomNumberGenerator.new()
func _init(): rng.randomize()
func set_seed(value:int): rng.seed=value
func _transition(value):
	state=value; clock=0.0
	state_changed.emit(value)
func prepare():
	tension=.45; progress=0; low_clock=0; high_clock=0; last_reason=""
	_transition(State.PREPARE)
func cast(power:float,valid_water:bool)->bool:
	if state!=State.PREPARE: return false
	cast_power=clampf(power,0,1)
	if not valid_water:
		_escape("落点在岸上。调整方向和蓄力，马上可以再试。")
		return false
	wait_duration=rng.randf_range(2.4,4.2)
	_transition(State.CASTING)
	return true
func strike()->bool:
	if state==State.WAITING:
		_escape("提竿早了。等浮标明显没入水面，再按空格。")
		return false
	if state!=State.BITE: return false
	_transition(State.HOOKED)
	return true
func tick(delta:float,reeling:bool):
	if state in [State.INACTIVE,State.PREPARE,State.CAUGHT,State.ESCAPED]: return
	clock+=delta
	match state:
		State.CASTING:
			if clock>=.65: _transition(State.WAITING)
		State.WAITING:
			if clock>=wait_duration: _transition(State.BITE)
		State.BITE:
			if clock>bite_window: _escape("鱼已经松口。看见浮标沉下去时，按空格提竿。")
		State.HOOKED:
			if clock>=.30: _transition(State.REELING)
		State.REELING:
			# Periodic surges are visible in fish motion and the tension indicator.
			# No random rolls can break the line or deny an earned catch.
			var surge=sin(clock*1.7)*.025
			tension=clampf(tension+delta*((.225 if reeling else -.27)+surge),0,1)
			var productive=reeling and tension>=.23 and tension<=.86
			progress=clampf(progress+delta*(.152 if productive else (.035 if reeling else -.012)),0,1)
			high_clock=high_clock+delta if tension>=.96 else maxf(0,high_clock-delta*2)
			low_clock=low_clock+delta if tension<=.12 else maxf(0,low_clock-delta*2)
			if high_clock>=.55: _escape("线绷得太紧，鱼脱钩了。下次张力偏高时松开左键。")
			elif low_clock>=2.4: _escape("鱼线松了太久。按住左键收线，把张力带回中段。")
			elif progress>=1:
				catch_serial+=1
				_transition(State.CAUGHT)
				caught.emit()
func nibble()->float:
	if state==State.BITE: return 1.0
	if state!=State.WAITING: return 0.0
	return clampf((clock-(wait_duration-.85))/.85,0,1)
func cancel(): _transition(State.INACTIVE)
func _escape(reason:String):
	last_reason=reason
	_transition(State.ESCAPED)
	escaped.emit(reason)
