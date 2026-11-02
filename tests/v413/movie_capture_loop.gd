extends SceneTree
# Capture-only harness: load the released main scene and flush the current render
# after node processing, even when Windows marks the native window as occluded.
# No gameplay state, input, time scale, camera or animation is modified here.
var capture_calls:=0
func _initialize():
 print("MOVIE_CAPTURE_DRIVER_ACTIVE")
 process_frame.connect(queue_capture)
 call_deferred("start_game")
func start_game():
 root.add_child(load(ProjectSettings.get_setting("application/run/main_scene")).instantiate())
func queue_capture():call_deferred("capture_current_frame")
func capture_current_frame():
 RenderingServer.force_draw(false)
 capture_calls+=1
func _finalize():print("MOVIE_CAPTURE_RENDER_CALLS ",capture_calls)
