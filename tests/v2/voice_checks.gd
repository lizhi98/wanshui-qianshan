extends SceneTree
var errors:=0
func _initialize(): call_deferred("run")
func check(value:bool,label:String):
	print(("PASS " if value else "FAIL ")+label)
	if not value: errors+=1
func run():
	var game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	await create_timer(.3).timeout
	game.started=true; game.paused=false
	var audio=game.audio
	check(audio.voice_manifest.size()>=50,"50 expressive Chinese dialogue clips available")
	for entry in audio.voice_manifest.values():
		check(entry.get("gender","")=="male" and entry.get("speaker","") in ["Uncle_Fu","Eric","Dylan"],"explicitly mapped to a documented Chinese male voice")
		check(entry.get("engine","")=="Qwen3-TTS" and not entry.get("instruct","").is_empty(),"line has actual expressive model output and its own direction")
		var stream=load(entry.file)
		check(stream is AudioStreamWAV and stream.get_length()>.3,"nonempty playable speech "+entry.who)
	game.say("林川","同志，过来搭把手！")
	game.say("林川","同志，过来搭把手！")
	game.say("阿木","来了！我接另一头！")
	await create_timer(.2).timeout
	check(audio.voice.playing and audio.voice_queue.size()==1,"single player serializes voices and suppresses duplicate line")
	check(game.hud.bark_label.text=="林川：同志，过来搭把手！","subtitle starts with its matching voice")
	var pos=audio.voice.get_playback_position(); game.paused=true
	await create_timer(.3).timeout
	check(absf(audio.voice.get_playback_position()-pos)<.15,"pause freezes voice playback")
	game.paused=false
	await audio.voice.finished
	await create_timer(.4).timeout
	check(audio.voice.playing and game.hud.bark_label.text=="阿木：来了！我接另一头！","next voice and subtitle begin after previous voice finishes")
	audio.clear_voice()
	check(not audio.voice.playing and audio.voice_queue.is_empty() and game.hud.bark_label.text.is_empty(),"reset clears playback, queue and subtitles")
	for node in game.find_children("*","AudioStreamPlayer",true,false): node.stop(); node.stream=null
	game.queue_free(); await process_frame; await create_timer(.3).timeout
	print("VOICE FAILURES ",errors); quit(1 if errors else 0)
