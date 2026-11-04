extends Node
## Explicitly arranged motion inspection video, not a playthrough or reward test.
var g
var follow=false
var follow_actor
func wait(seconds:float):await get_tree().create_timer(seconds).timeout
func label(text:String):g.hud.show_dialogue("人物动作验收 · 测试摆位，非通关录像",text)
func camera(actor,offset:Vector3,focus:Vector3,fov:=49.0):
	g.view.cinematic=true;g.view.camera.global_position=actor.position+offset;g.view.camera.look_at(actor.position+focus);g.view.camera.fov=fov
func _process(_delta):
	if follow and is_instance_valid(follow_actor):camera(follow_actor,Vector3(2.8,1.8,4.3),Vector3(0,.85,0),52)
func run(scene):
	g=scene;g.store.path="user://golden_hook_v11_action_lab.json";g.begin_chapter(true);g.set_performance_mode(false);g.audio.voice_volume=0;g.busy=true;g.player.locked=false;g.view.cinematic=true
	g.player.position=g.world.at_ground(Vector3(-26,0,20));g.player.rotation.y=PI;g.player.rotation_direction=PI;g.view.rotation.y=0
	follow=true;follow_actor=g.player
	label("步行：共用完整 Walk 动画与脚掌接触求解")
	Input.action_press("move_forward");await wait(2.5);Input.action_release("move_forward");await wait(.7)
	label("转向、起步与停步：物理控制器拥有根节点")
	Input.action_press("move_right");await wait(2.3);Input.action_release("move_right");await wait(.7)
	label("奔跑：完整 Jog 动作，左右肢体交替，按实际速度调节步频")
	Input.action_press("move_forward");Input.action_press("sprint");await wait(2.8);Input.action_release("move_forward");Input.action_release("sprint");await wait(1.0)
	follow=false;g.player.locked=true;g.shi.moving=false;g.shi.position=g.world.at_ground(g.player.position+Vector3(1,0,-1));g.shi.rotation.y=0;g.shi.visual.reset_pose()
	camera(g.shi,Vector3(.8,1.4,2.4),Vector3(0,.8,0))
	label("坐下：Sitting_Enter → Sitting_Idle；双脚贴合地面")
	g.shi.visual.posture="seated";await wait(3.0)
	label("起身：Sitting_Exit，再恢复普通站姿")
	g.shi.visual.posture="rising";await wait(g.shi.visual.animator.get_animation("Sitting_Exit").length);g.shi.visual.reset_pose();await wait(.7)
	g.player.rotation.y=0;g.player.visual.posture="kneel";g.player.visual.hold("hook")
	camera(g.player,Vector3(.42,.84,1.1),Vector3(-.01,.55,.34),39);label("俯身取物与捏住针眼：手腕方向与指节接触")
	await wait(2.5)
	g.player.visual.hold("bowl");g.player.visual.posture="standing"
	camera(g.player,Vector3(-.6,1.55,1.3),Vector3(0,1.15,.30),40);label("持碗：手掌围住碗壁，手指与器具对齐")
	await wait(2.0)
	g.shi.position=g.world.at_ground(g.player.position+Vector3(0,0,1.2));g.shi.visual.posture="seated";g.shi.face(g.player.position)
	camera(g.player,Vector3(2.4,1.5,1.7),Vector3(0,.8,.6),49);label("递碗与接碗：同一只碗平滑交接")
	await g._handoff(g.shi,g.session_epoch);await wait(1.2)
	g.story.step="simmer";g.story.hook_form=4;g.story.inventory.hook=1;g.story.fish_total=2;g.story.done.place_parts=true;g.player.visual.reset_pose();g._simmer()
	label("搅拌：人物走到锅边，真实木勺沿汤面做圆周运动")
	for i in 8:camera(g.elder,Vector3(.8,1.5,1.8),Vector3(.25,.55,0),44);await wait(1.0)
	g._cancel_dialogue();g.busy=true;g.player.locked=true
	g.elder.position=g.world.points.secret;g.elder.rotation.y=0;g.elder.visual.reset_pose();g.elder.visual.posture="seated";g.elder.visual.hold("scraps")
	camera(g.elder,Vector3(.45,1.1,1.3),Vector3(0,.68,.32),40);label("秘密中的碗：草根、鱼骨与人物手部")
	await wait(3.0)
	g.elder.visual.reset_pose();g.elder.position=g.world.points.last_elder;g.elder.rotation.y=0;g.elder.visual.posture="collapsed"
	camera(g.elder,Vector3(2.6,1.3,-.6),Vector3(0,.3,-.25),54);label("虚弱倒下：完整下落，再进入收拢双臂的稳定姿态")
	await wait(3.2)
	for pair in [[Vector3(0,.7,-2.3),"临终姿态 · 正面"],[Vector3(2.6,.8,0),"临终姿态 · 侧面"],[Vector3(.01,3.8,.01),"临终姿态 · 俯视"]]:
		camera(g.elder,pair[0],Vector3(0,.12,-.3),54);label(pair[1]);await wait(2.6)
	label("动作验收结束：测试场景与完整输入通关录像分别交付")
	await wait(1.2);g.return_to_menu();g.queue_free();await get_tree().process_frame;await get_tree().process_frame;OS.delay_msec(80);get_tree().quit()
