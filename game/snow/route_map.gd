extends Control
var progress:=0.0
var font:Font
func _ready():font=load("res://assets/remaster/fonts/NotoSansSC.ttf");mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta):progress=minf(1,progress+delta/6.5);queue_redraw()
func _draw():
	var rect=Rect2(size*Vector2(.17,.15),size*Vector2(.66,.69));draw_style_box(_style(),rect)
	var from=size*Vector2(.36,.69);var to=size*Vector2(.66,.37)
	for i in 8:
		var y=size.y*(.28+i*.055);var points=PackedVector2Array()
		for j in 36:points.append(Vector2(size.x*(.22+j*.016),y+sin(j*.28+i)*18))
		draw_polyline(points,Color(.48,.59,.62,.18),1)
	var route=PackedVector2Array([from,from.lerp(to,.33)+Vector2(-16,-24),from.lerp(to,.67)+Vector2(16,-10),to])
	draw_polyline(route,Color(.55,.42,.29,.4),3)
	var visible_route=PackedVector2Array([from]);var scaled=progress*3
	for i in 3:
		if scaled>=i+1:visible_route.append(route[i+1])
		elif scaled>i:visible_route.append(route[i].lerp(route[i+1],scaled-i));break
	if visible_route.size()>1:draw_polyline(visible_route,Color("bf6e4d"),3,true)
	draw_circle(from,5,Color("d7b778"));draw_circle(to,5,Color("ece4cf"))
	if font:
		draw_string(font,size*Vector2(.23,.25),"万水千山 · 长征路线",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("ece4cf"))
		draw_string(font,from+Vector2(-68,29),"泸定桥",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("d7b778"))
		draw_string(font,to+Vector2(-38,-17),"夹金山",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("ece4cf"))
		draw_string(font,size*Vector2(.23,.78),"1935年6月 · 路线示意，非等比例地图",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("b2c0b8"))
func _style()->StyleBoxFlat:
	var style=StyleBoxFlat.new();style.bg_color=Color(.035,.06,.07,.95);style.border_color=Color(.7,.58,.35,.5);style.set_border_width_all(1);style.set_corner_radius_all(7);return style
