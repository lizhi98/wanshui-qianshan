extends RefCounted
## Story rules have no timer and no player-speed input. The elder's literary
## fate follows the assistance scene, independent of fishing retries.
signal changed
const STEPS=["supplies","craft","heat","bend","tie","mount","first_fishing","cook_fish","cook_greens","light_fire","simmer","serve","secret","march","search","last_fishing","last_cook","last_deliver","farewell","keepsake","leave","archive"]
const ITEMS=["greens","needle","thread","branch","hook","fish","soup","keepsake"]
const SUPPLIES=["bag_a","bag_b","comrade_a","comrade_b","ration","greens_a","greens_b"]
var step := "supplies"
var done:Dictionary={}
var inventory:Dictionary={"greens":0,"needle":0,"thread":0,"branch":0,"hook":0,"fish":0,"soup":0,"keepsake":0}
var hook_id := "grassland_needle_01"
var hook_form := 0 # 0 needle, 1 heated, 2 curved, 3 tied, 4 mounted, 5 worn, 6 wrapped
var elder_fate := "alive"
var fish_total := 0
func perform(action:String)->bool:
	if done.get(action,false): return false
	var accepted=false
	match step:
		"supplies":
			if action in SUPPLIES:
				accepted=true
				if action.begins_with("greens_"): inventory.greens+=1
			elif action=="deliver_supplies":
				var ready=true
				for id in SUPPLIES:
					if not done.get(id,false): ready=false
				if ready: step="craft"; accepted=true
		"craft":
			if action in ["needle","thread","branch"]:
				inventory[action]+=1; accepted=true
			elif action=="place_parts" and inventory.needle==1 and inventory.thread==1 and inventory.branch==1:
				inventory.needle=0; inventory.thread=0; inventory.branch=0
				step="heat"; accepted=true
		"heat":
			if action=="heat": hook_form=1; step="bend"; accepted=true
		"bend":
			if action=="bend": hook_form=2; step="tie"; accepted=true
		"tie":
			if action=="tie": hook_form=3; step="mount"; accepted=true
		"mount":
			if action=="mount": hook_form=4; inventory.hook=1; step="first_fishing"; accepted=true
		"cook_fish":
			if action=="put_fish" and inventory.fish>=2:
				inventory.fish-=2; step="cook_greens"; accepted=true
		"cook_greens":
			if action=="put_greens" and inventory.greens>=2:
				inventory.greens-=2; step="light_fire"; accepted=true
		"light_fire":
			if action=="light_fire": step="simmer"; accepted=true
		"simmer":
			if action=="finish_soup": inventory.soup=3; step="serve"; accepted=true
		"serve":
			if action in ["serve_a","serve_b"] and inventory.soup>0:
				inventory.soup-=1; accepted=true
			elif action=="drink_soup" and done.get("serve_a",false) and done.get("serve_b",false) and inventory.soup==1:
				inventory.soup=0; step="secret"; accepted=true
		"secret":
			if action=="understand": step="march"; accepted=true
		"march":
			if action=="continue_march": step="search"; accepted=true
		"search":
			if action=="find_elder": step="last_fishing"; accepted=true
		"last_cook":
			if action=="last_cook" and inventory.fish==1:
				inventory.fish=0; inventory.soup=1; step="last_deliver"; accepted=true
		"last_deliver":
			if action=="last_deliver" and inventory.soup==1:
				inventory.soup=0; step="farewell"; accepted=true
		"farewell":
			if action=="farewell": elder_fate="sacrificed"; hook_form=5; step="keepsake"; accepted=true
		"keepsake":
			if action=="collect_hook" and inventory.hook==1:
				inventory.hook=0; inventory.keepsake=1; hook_form=6; step="leave"; accepted=true
		"leave":
			if action=="leave": step="archive"; accepted=true
	if accepted:
		done[action]=true
		changed.emit()
	return accepted
func add_fish()->bool:
	if step not in ["first_fishing","last_fishing"] or inventory.hook!=1: return false
	inventory.fish+=1; fish_total+=1
	if step=="first_fishing" and inventory.fish>=2: step="cook_fish"
	elif step=="last_fishing": step="last_cook"
	changed.emit()
	return true
func snapshot()->Dictionary:
	return {"step":step,"done":done.duplicate(true),"inventory":inventory.duplicate(true),"hook_id":hook_id,"hook_form":hook_form,"elder_fate":elder_fate,"fish_total":fish_total}
func restore(data:Dictionary)->bool:
	if data.get("step") not in STEPS or data.get("hook_id")!="grassland_needle_01": return false
	if data.get("inventory") is not Dictionary or data.get("done") is not Dictionary: return false
	if data.get("elder_fate") not in ["alive","sacrificed"]: return false
	for id in ITEMS:
		var value=data.inventory.get(id)
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)) or value!=floor(value) or value<0 or value>3: return false
	for value in data.done.values():
		if typeof(value)!=TYPE_BOOL: return false
	for id in ["hook_form","fish_total"]:
		var value=data.get(id)
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or value!=floor(value) or value<0 or value>6: return false
	if data.inventory.keepsake>1 or data.inventory.hook>1 or data.inventory.keepsake+data.inventory.hook>1: return false
	var index=STEPS.find(data.step)
	if index>=STEPS.find("first_fishing") and index<=STEPS.find("keepsake") and (data.inventory.hook!=1 or data.hook_form<4): return false
	if index>=STEPS.find("heat") and not data.done.get("place_parts",false): return false
	if index>=STEPS.find("cook_fish") and data.fish_total<2: return false
	if index>=STEPS.find("last_cook") and data.fish_total!=3: return false
	if data.step in ["leave","archive"] and (data.inventory.keepsake!=1 or data.elder_fate!="sacrificed"): return false
	step=data.step; done=data.done.duplicate(true); inventory=data.inventory.duplicate(true)
	hook_id=data.hook_id; hook_form=int(data.hook_form); fish_total=int(data.fish_total); elder_fate=data.elder_fate
	return true
