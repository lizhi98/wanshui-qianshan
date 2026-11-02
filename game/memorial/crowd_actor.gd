extends Node3D
var mission
var visual
func setup(m):
	mission=m;visual=load("res://game/memorial/visual.gd").new();add_child(visual)
