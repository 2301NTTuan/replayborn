extends Node

signal settings_changed
const SCHEMA: int = 1
var save_path: String = "user://profile.json"
var data: Dictionary = defaults()
var warning: String = ""
var selected_weapon: int = 0
var practice: bool = false

func _ready() -> void:
	load_profile()

func defaults() -> Dictionary:
	return {"version": SCHEMA, "volume": 0.65, "music": 0.35, "reduced": false, "language": "vi", "tutorial": false, "runs": 0, "wins": 0, "kills": 0, "best_seconds": 0.0, "palette": 0, "weapon": 0, "character": 0, "map": 0}

func valid_profile(value: Variant) -> bool:
	if not value is Dictionary or value.get("version") != SCHEMA:
		return false
	for key in ["volume", "music", "runs", "wins", "kills", "best_seconds"]:
		if not (value.get(key) is float or value.get(key) is int):
			return false
	return value.get("language") in ["vi", "en"] and value.get("reduced") is bool and value.get("tutorial") is bool

func read_profile(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 65536:
		return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return null
	return parser.data

func load_profile() -> void:
	warning = ""
	data = defaults()
	var loaded: Variant = read_profile(save_path)
	if not valid_profile(loaded):
		loaded = read_profile(save_path + ".bak")
		if FileAccess.file_exists(save_path):
			warning = "save_recovered" if valid_profile(loaded) else "save_reset"
	if valid_profile(loaded):
		for key in data:
			data[key] = loaded.get(key, data[key])
		data.volume = clampf(data.volume, 0, 1)
		data.music = clampf(data.music, 0, 1)
		for key in ["runs", "wins", "kills"]:
			data[key] = clampi(int(data[key]), 0, 100000000)
		data.best_seconds = clampf(data.best_seconds, 0, 86400)
		data.palette = clampi(int(data.palette), 0, 2) if data.palette is float or data.palette is int else 0
		data.weapon = clampi(int(data.weapon), 0, 2) if data.weapon is float or data.weapon is int else 0
		data.character = clampi(int(data.character), 0, 9) if data.character is float or data.character is int else 0
		data.map = clampi(int(data.map), 0, 9) if data.map is float or data.map is int else 0
		if not palette_unlocked(data.palette):
			data.palette = 0
		selected_weapon = data.weapon

func palette_unlocked(index: int) -> bool:
	return index == 0 or (index == 1 and data.kills >= 100) or (index == 2 and data.wins >= 1)

func save_profile() -> Error:
	var temporary: String = save_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		warning = "save_failed"
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		warning = "save_failed"
		return write_error
	# Keep a known-valid backup, including when recovering a corrupt primary.
	if valid_profile(read_profile(save_path)):
		var backup_error := DirAccess.copy_absolute(save_path, save_path + ".bak")
		if backup_error != OK:
			warning = "save_failed"
			return backup_error
	var result := DirAccess.rename_absolute(temporary, save_path)
	if result != OK:
		warning = "save_failed"
	else:
		warning = ""
	return result

func setting(key: String, value: Variant) -> void:
	if key not in ["volume", "music", "reduced", "language", "tutorial", "weapon", "palette", "character", "map"]:
		return
	data[key] = value
	save_profile()
	settings_changed.emit()

func finish_run(won: bool, seconds: float, kills: int) -> void:
	if practice:
		return
	data.runs += 1
	data.wins += 1 if won else 0
	data.kills += kills
	data.best_seconds = maxf(data.best_seconds, seconds)
	save_profile()
