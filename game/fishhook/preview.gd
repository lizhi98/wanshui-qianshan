extends Control

func _ready():
	$Panel/Content/Back.grab_focus()

func _return_to_chapters():
	get_tree().change_scene_to_file("res://game/chapters/main.tscn")
