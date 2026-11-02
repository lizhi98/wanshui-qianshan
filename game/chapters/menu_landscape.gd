extends Control
# A hand-drawn silhouette of the Dadu crossing, in a 1280 by 720 design space.

func _draw():
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(1280, 720))
	draw_rect(Rect2(0, 0, 1280, 720), Color("d9cdb2"))
	draw_circle(Vector2(451, 245), 83, Color("b6654c"), true, -1, true)
	_ridge([0,372, 105,328, 166,341, 258,269, 302,285, 357,249, 415,289, 488,217, 530,250, 605,206, 685,275, 770,238, 931,318, 1080,235, 1280,275], Color("a5afa0"))
	_ridge([0,395, 77,386, 162,339, 222,366, 282,329, 336,349, 395,314, 449,350, 524,273, 546,289, 605,244, 678,316, 729,282, 785,333, 888,304, 1010,354, 1140,285, 1280,334], Color("778e83"))
	_ridge([0,443, 104,416, 177,425, 263,384, 301,392, 349,374, 425,399, 493,354, 552,371, 610,327, 680,360, 764,322, 875,381, 1016,341, 1120,360, 1280,319], Color("466b62"))
	draw_rect(Rect2(0, 463, 1280, 257), Color("849c8a"))
	for i in 18:
		var x := float((i * 97) % 690)
		var y := 476.0 + i * 8
		draw_line(Vector2(x, y), Vector2(x + 24 + i % 5 * 12, y), Color("a8b4a0"), 1.5)
	var ink := Color("263e37")
	for pier in [138, 462]:
		draw_rect(Rect2(pier - 4, 407, 8, 68), ink)
		draw_rect(Rect2(pier - 14, 405, 28, 5), ink)
	draw_line(Vector2(138, 443), Vector2(462, 443), ink, 5, true)
	for i in 37:
		var t := i / 36.0
		var x := lerpf(138, 462, t)
		var y := 413.0 + 22.0 * sin(t * PI)
		draw_line(Vector2(x, y), Vector2(x, 443), ink, 1.2, true)
		if i < 36:
			draw_line(Vector2(x, y), Vector2(x + 9, 413 + 22 * sin((i + 1) * PI / 36)), ink, 2, true)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 423), Vector2(64, 430), Vector2(148, 438), Vector2(124, 459), Vector2(98, 492), Vector2(39, 510), Vector2(0, 536)]), ink)
	_ridge([400,716, 539,601, 550,538, 503,505, 451,452, 461,439, 495,435, 566,411, 644,401, 715,361, 825,392, 1010,323, 1280,381], Color("294c43"))
	_ridge([0,583, 86,550, 160,567, 253,603, 339,615, 440,654, 490,680, 631,716], Color("355b50"))

func _ridge(coords: Array, color: Color):
	var points := PackedVector2Array()
	for i in range(0, coords.size(), 2):
		points.append(Vector2(coords[i], coords[i + 1]))
	points.append(Vector2(coords[-2], 720))
	points.append(Vector2(coords[0], 720))
	draw_colored_polygon(points, color)
