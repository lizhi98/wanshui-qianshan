extends RefCounted
const ORDER=["march","recon","escort","repair","traversal","relay","complete"]
var current="march"
var done:Dictionary={}
func finish(id:String)->bool:
	if id!=current or id=="complete": return false
	done[id]=true
	current=ORDER[ORDER.find(id)+1]
	return true
func snapshot()->Dictionary: return {"current":current,"done":done.duplicate(true)}
func restore(data:Dictionary)->bool:
	var id=data.get("current","")
	var completed=data.get("done",{})
	if completed is Dictionary:
		completed=completed.duplicate(true);completed.erase("modern")
	if id=="modern":id="complete"
	if not id in ORDER or completed is not Dictionary: return false
	var index=ORDER.find(id)
	for i in ORDER.size():
		if bool(completed.get(ORDER[i],false))!=(i<index): return false
	current=id
	done=completed.duplicate(true)
	return true
