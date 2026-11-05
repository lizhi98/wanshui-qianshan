extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func run():
 var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);await process_frame
 g.begin_chapter(true);g.set_process(false)
 var initial=g.interactions()
 for id in g.Story.SUPPLIES:g.story.perform(id)
 g.player.position=g.world.at_ground(g.elder.position+Vector3(1,0,.25))
 await g._do_action({"id":"deliver_supplies","point":g.world.points.elder})
 check(g.elder.visual.posture=="standing","elder stands to receive supplies and speak")
 check(g.player.visual.posture!="kneel","player does not kneel while handing over supplies")
 check(g.story.step=="craft","delivery still advances objective")
 check(g.dialogue_rows[g.dialogue_index].id=="supplies_done_02","correct line plays first")
 check(absf(g.dialogue_left-g.audio.voice.stream.get_length()-1.25)<.01,"1.25 seconds after road line")
 g.dialogue_left=.2;g._process(.1)
 check(g.dialogue_rows[g.dialogue_index].id=="supplies_done_02","next line waits through pause")
 g._process(.11)
 check(g.dialogue_rows[g.dialogue_index].id=="supplies_done_04","fish line follows pause")
 check(absf(g.dialogue_left-g.audio.voice.stream.get_length()-.14)<.01,"other lines retain normal timing")
 for row in initial:check(not row.title.contains("剧情"),"interaction copy stays in world")
 g.story.step="supplies"
 check(not g.objective_text().contains("剧情"),"objective wording cleaned")
 g.story.step="cook_greens"
 check(not g.interactions()[0].title.contains("剧情"),"cooking prompt wording cleaned")
 g.queue_free();await process_frame;await create_timer(.4).timeout
 print("SUPPLIES_POLISH_CHECK failures=",failures);quit(1 if failures else 0)
