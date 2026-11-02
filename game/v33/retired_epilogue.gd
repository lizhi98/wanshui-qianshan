extends Node3D
# Compatibility holder for shared base menus; no camera, UI or reconstruction.
var mission
var active:=false
var scanned:Array=[]
func stop():active=false
