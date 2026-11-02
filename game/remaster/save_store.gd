extends RefCounted
const VERSION=2
const STAGES=["prologue","approach","prepare","signal","combat","brace","timber","carrying","crossing","reunion","modern","complete"]
var path="user://remaster_campaign_v2.json"
var last_error := ""
func write(data: Dictionary) -> bool:
	last_error=""
	data=data.duplicate(true)
	data["version"]=VERSION
	if not valid(data):
		last_error="检查点数据不完整"
		return false
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if not file:
		last_error="无法写入存档目录"
		return false
	file.store_string(JSON.stringify(data,"\t"))
	file.flush()
	file.close()
	var result=DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
	if result!=OK:
		last_error="无法替换检查点文件"
	return result==OK
func read() -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is not Dictionary or not valid(parsed): return {}
	return parsed
func valid(data: Dictionary) -> bool:
	return int(data.get("version",0))==VERSION and data.get("stage","") in STAGES and data.get("tasks",null) is Dictionary and data.get("position",null) is Array and data.position.size()==3
func exists() -> bool: return not read().is_empty()
