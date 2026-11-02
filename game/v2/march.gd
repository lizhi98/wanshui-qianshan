extends Node3D
signal completed(result:Dictionary)
var mission
var active=false
var jumped=false
var supply=false
var log_position=Vector3(0,0,43)
var bag_position=Vector3(-2.6,0,36)
var nodes:Array=[]
func setup(m):
	mission=m
	var obstacle=mission.world.box(Vector3(2.2,.48,.6),log_position+Vector3(0,.23,0),mission.world.wood)
	obstacle.name="MarchFallenTimber"
	nodes.append(obstacle)
	var bag=mission.world.box(Vector3(.65,.5,.7),bag_position+Vector3(0,.25,0),mission.world.wood)
	nodes.append(bag)
	var label=Label3D.new(); label.text="接应物资 · 绳索与弹药"; label.font_size=34; label.pixel_size=.012
	bag.add_child(label); label.position=Vector3(0,.85,0)
func start(state:Dictionary={}):
	active=true; jumped=bool(state.get("jumped",false)); supply=bool(state.get("supply",false))
	mission.player.locked=false
func tick(_delta):
	if not active: return
	var p=mission.player.position
	if Vector2(p.x-log_position.x,p.z-log_position.z).length()<2 and p.y>.55 and not jumped:
		jumped=true; mission.say("林川","跨过去了，带上接应物资。")
		mission.save_checkpoint()
	if jumped and supply and p.z<31.5:
		active=false; completed.emit(snapshot())
func interact():
	if not active or supply: return
	if mission.player.position.distance_to(bag_position)<2:
		supply=true; mission.combat.reserve=30
		mission.say("阿木","绳索我背着。到前面先看清桥。")
		mission.save_checkpoint()
func status()->Dictionary:
	return {"objective":"跨过倒木，带上接应物资" if not jumped or not supply else "沿路抵达桥头",
	"hint":"Space 跳过倒木" if not jumped else ("E 领取绳索与弹药" if not supply else "WASD 前进 · Shift 奔跑"),
	"progress":(int(jumped)+int(supply))/3.0,"detail":"跳跃 %s  ·  物资 %s"%["✓" if jumped else "○","✓" if supply else "○"],
	"waypoint":log_position+Vector3(0,1,0) if not jumped else (bag_position+Vector3(0,1,0) if not supply else Vector3(0,1,30))}
func snapshot()->Dictionary: return {"jumped":jumped,"supply":supply}
func safe_position()->Vector3: return Vector3(0,.1,45) if not jumped else Vector3(0,.1,39)
func stop(): active=false
