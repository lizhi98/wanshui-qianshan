# Preserve the verified controller; V2 only delegates its special chain state.
extends "res://game/player.gd"
var balance_assist := true
func _physics_process(delta):
	super._physics_process(delta)
func jump():
	# Space belongs to the inspection/confirmation controls on the bridge.
	# A chapter change in that same frame must not also start a physical jump.
	if mission.get("ledger") and mission.ledger.current in ["repair","traversal","relay","modern","complete"]: return
	super.jump()
func _climb(delta):
	if mission.traversal and mission.traversal.active:
		mission.traversal.advance_player(delta)
	else:
		super._climb(delta)
