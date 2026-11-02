extends Node
func finish(game: Node, code: int):
	var tree=get_tree()
	game.queue_free()
	await tree.process_frame
	await tree.create_timer(.3).timeout
	tree.quit(code)
