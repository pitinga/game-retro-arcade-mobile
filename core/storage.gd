extends RefCounted
const SCHEMA: int = 1
var path: String
var prefs: Dictionary = defaults()
var records: Dictionary = {}
func _init(file_path: String = "user://arcade.json") -> void:
	path = file_path
static func defaults() -> Dictionary:
	return {"language":"pt","music":true,"effects":true,"vibration":true,"reduced_motion":false,"left_handed":false,"control_size":100,"control_opacity":100}
func load_data() -> void:
	prefs = defaults()
	records = {}
	for candidate: String in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(candidate))
		if not raw is Dictionary or raw.get("schema",0) != SCHEMA:
			continue
		var p: Variant = raw.get("prefs",{})
		if p is Dictionary:
			for key: String in prefs:
				var value: Variant = p.get(key,prefs[key])
				if key == "language" and value in ["pt","en"]:
					prefs[key] = value
				elif prefs[key] is bool and value is bool:
					prefs[key] = value
				elif key in ["control_size","control_opacity"] and (value is float or value is int) and is_finite(float(value)):
					prefs[key] = clampi(int(value),50,150 if key == "control_size" else 100)
		var r: Variant = raw.get("records",{})
		if r is Dictionary:
			for key: Variant in r:
				var value: Variant = r[key]
				if key is String and (value is float or value is int) and is_finite(float(value)) and value >= 0 and value <= 9007199254740991 and floor(float(value)) == float(value):
					records[key] = int(value)
		return
func save() -> bool:
	var tmp := path+".tmp"
	var file := FileAccess.open(tmp,FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"schema":SCHEMA,"prefs":prefs,"records":records}))
	file.flush()
	file.close()
	var dest := ProjectSettings.globalize_path(path)
	var temp := ProjectSettings.globalize_path(tmp)
	var bak := dest+".bak"
	if FileAccess.file_exists(path):
		# Keep a last-known-good backup, never overwrite it with corrupted primary.
		var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if old is Dictionary and old.get("schema",0) == SCHEMA:
			if DirAccess.copy_absolute(dest,bak) != OK:
				return false
	return DirAccess.rename_absolute(temp,dest) == OK
func record(id: String, difficulty: String, rules: String, score: int) -> bool:
	if preload("res://core/catalog.gd").find(id).is_empty() or not difficulty in ["easy","normal","hard"] or rules.is_empty() or ":" in rules or score < 0 or score > 9007199254740991:
		return false
	var key := id+":"+difficulty+":"+rules
	var previous: int = records.get(key,0)
	if score <= previous:
		return true
	records[key] = score
	if save():
		return true
	if previous == 0:
		records.erase(key)
	else:
		records[key] = previous
	return false
