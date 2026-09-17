extends Node

signal settings_changed

const SCHEMA: int = 2
const META_STATS: Array[String] = ["hp", "damage", "armor", "haste"]
const META_MAX_LEVEL: int = 10

var save_path: String = "user://profile.json"
var data: Dictionary = defaults()
var warning: String = ""
var practice: bool = false

func _ready() -> void:
	load_profile()

func defaults() -> Dictionary:
	return {
		"version": SCHEMA,
		"language": "vi",
		"tutorial": false,
		"volume": 0.65,
		"music": 0.35,
		"sfx": 0.75,
		"reduced": false,
		"shake": true,
		"haptics": true,
		"contrast": false,
		"runs": 0,
		"wins": 0,
		"kills": 0,
		"best_seconds": 0.0,
		"gold": 500,
		"upgrade_core": 25,
		"weapon": 0,
		"weapon_unlocks": [true, false, false],
		"meta_upgrades": {"hp": 0, "damage": 0, "armor": 0, "haste": 0},
		"stats": {"circuits": 0, "captured": 0, "bosses": 0}
	}

func safe_int(value: Variant, fallback: int, minimum: int = 0, maximum: int = 2147483647) -> int:
	return clampi(int(value), minimum, maximum) if value is int or value is float else fallback

func safe_float(value: Variant, fallback: float, minimum: float = 0.0, maximum: float = 1.0) -> float:
	return clampf(float(value), minimum, maximum) if value is int or value is float else fallback

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

func is_profile_candidate(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var version: Variant = value.get("version")
	return (version is int or version is float) and int(version) in [1, SCHEMA]

func migrate_profile(source: Dictionary) -> Dictionary:
	var migrated: Dictionary = source.duplicate(true)
	if safe_int(migrated.get("version", 1), 1) == 1:
		migrated.version = SCHEMA
		migrated.weapon_unlocks = [true, safe_int(migrated.get("wins", 0), 0) > 0, safe_int(migrated.get("wins", 0), 0) > 0]
		migrated.stats = {"circuits": 0, "captured": 0, "bosses": 0}
	return migrated

func sanitize_profile(source: Dictionary) -> Dictionary:
	var result: Dictionary = defaults()
	result.language = str(source.get("language", result.language)) if str(source.get("language", "vi")) in ["vi", "en"] else "vi"
	for key in ["tutorial", "reduced", "shake", "haptics", "contrast"]:
		result[key] = source.get(key, result[key]) if source.get(key, result[key]) is bool else result[key]
	for key in ["volume", "music", "sfx"]:
		result[key] = safe_float(source.get(key, result[key]), result[key])
	for key in ["runs", "wins", "kills", "gold", "upgrade_core"]:
		result[key] = safe_int(source.get(key, result[key]), result[key], 0, 100000000)
	result.best_seconds = safe_float(source.get("best_seconds", 0.0), 0.0, 0.0, 86400.0)
	var raw_meta: Variant = source.get("meta_upgrades", {})
	var meta: Dictionary = raw_meta if raw_meta is Dictionary else {}
	for stat in META_STATS:
		result.meta_upgrades[stat] = safe_int(meta.get(stat, 0), 0, 0, META_MAX_LEVEL)
	var raw_unlocks: Variant = source.get("weapon_unlocks", [true, false, false])
	if raw_unlocks is Array:
		for index in range(1, mini(3, raw_unlocks.size())):
			result.weapon_unlocks[index] = raw_unlocks[index] if raw_unlocks[index] is bool else false
	result.weapon_unlocks[0] = true
	result.weapon = safe_int(source.get("weapon", 0), 0, 0, 2)
	if not result.weapon_unlocks[result.weapon]:
		result.weapon = 0
	var raw_stats: Variant = source.get("stats", {})
	var statistics: Dictionary = raw_stats if raw_stats is Dictionary else {}
	for key in ["circuits", "captured", "bosses"]:
		result.stats[key] = safe_int(statistics.get(key, 0), 0, 0, 100000000)
	return result

func load_profile() -> void:
	warning = ""
	var loaded: Variant = read_profile(save_path)
	if not is_profile_candidate(loaded):
		loaded = read_profile(save_path + ".bak")
		if FileAccess.file_exists(save_path):
			warning = "save_recovered" if is_profile_candidate(loaded) else "save_reset"
	if is_profile_candidate(loaded):
		data = sanitize_profile(migrate_profile(loaded))
	else:
		data = defaults()

func save_profile() -> Error:
	data = sanitize_profile(data)
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
	if is_profile_candidate(read_profile(save_path)):
		var backup_error := DirAccess.copy_absolute(save_path, save_path + ".bak")
		if backup_error != OK:
			warning = "save_failed"
			return backup_error
	var result := DirAccess.rename_absolute(temporary, save_path)
	warning = "save_failed" if result != OK else ""
	return result

func setting(key: String, value: Variant) -> void:
	if key not in ["volume", "music", "sfx", "reduced", "language", "tutorial", "shake", "haptics", "contrast", "weapon"]:
		return
	if key == "weapon" and (not value is int or value < 0 or value >= 3 or not data.weapon_unlocks[value]):
		return
	data[key] = value
	save_profile()
	settings_changed.emit()

func meta_cost(stat: String) -> Dictionary:
	var level: int = safe_int(data.meta_upgrades.get(stat, 0), 0, 0, META_MAX_LEVEL)
	return {"gold": 120 + level * 95, "core": 4 + level * 3}

func upgrade_meta(stat: String) -> bool:
	if stat not in META_STATS:
		return false
	var level: int = int(data.meta_upgrades[stat])
	var cost: Dictionary = meta_cost(stat)
	if level >= META_MAX_LEVEL or data.gold < cost.gold or data.upgrade_core < cost.core:
		return false
	data.gold -= cost.gold
	data.upgrade_core -= cost.core
	data.meta_upgrades[stat] = level + 1
	save_profile()
	return true

func add_rewards(gold: int, core: int, persist: bool = true) -> void:
	data.gold = safe_int(data.gold, 0) + maxi(0, gold)
	data.upgrade_core = safe_int(data.upgrade_core, 0) + maxi(0, core)
	if persist:
		save_profile()

func finish_run(won: bool, seconds: float, kills: int, gold: int, cores: int, bosses: int, circuits: int = 0, captured: int = 0) -> void:
	if practice:
		return
	data.runs += 1
	data.wins += 1 if won else 0
	data.kills += maxi(0, kills)
	data.best_seconds = maxf(data.best_seconds, seconds)
	data.stats.bosses += maxi(0, bosses)
	data.stats.circuits += maxi(0, circuits)
	data.stats.captured += maxi(0, captured)
	if bosses >= 2:
		data.weapon_unlocks[1] = true
	if won:
		data.weapon_unlocks[2] = true
	add_rewards(gold + bosses * 30, cores + bosses * 2, false)
	save_profile()

func reset_progress() -> void:
	var language: String = data.language
	var settings := {"volume": data.volume, "music": data.music, "sfx": data.sfx, "reduced": data.reduced, "shake": data.shake, "haptics": data.haptics, "contrast": data.contrast}
	data = defaults()
	data.language = language
	for key in settings:
		data[key] = settings[key]
	save_profile()
	settings_changed.emit()
