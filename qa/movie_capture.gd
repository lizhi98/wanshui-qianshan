extends Node
# MovieMaker only. Windows may mark a covered/minimised native window as unable
# to draw while gameplay still advances. Flush the current viewport after node
# processing so add_frame() receives a fresh image, independently of presentation.
var rendered_frames:=0
func _ready():
 name="MovieCaptureRenderDriver"
 process_priority=1000000
 process_mode=Node.PROCESS_MODE_ALWAYS
func _process(_delta):call_deferred("capture_current_frame")
func capture_current_frame():
 RenderingServer.force_draw(false)
 rendered_frames+=1
func _exit_tree():print("MOVIE_CAPTURE_RENDER_CALLS ",rendered_frames)
