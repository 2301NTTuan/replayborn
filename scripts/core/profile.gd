extends Node

signal settings_changed
const SCHEMA: int = 1
const RARITIES: Array = ["THƯỜNG", "HIẾM", "HUYỀN THOẠI", "MYTHIC", "CỔ ĐẠI"]
const SLOTS: Array = ["ÁO", "QUẦN", "GIÀY", "GIÁP", "VŨ KHÍ"]
var save_path: String = "user://profile.json"
var data: Dictionary = defaults()
var warning: String = ""
var selected_weapon: int = 0
var practice: bool = false

func _ready() -> void:
	load_profile()

func defaults() -> Dictionary:
	return {"version": SCHEMA, "volume": 0.65, "music": 0.35, "reduced": false, "language": "vi", "tutorial": false, "runs": 0, "wins": 0, "kills": 0, "best_seconds": 0.0, "palette": 0, "weapon": 0, "character": 0, "map": 0, "gold": 500, "upgrade_core": 25, "meta_upgrades": {"hp": 0, "damage": 0, "armor": 0, "haste": 0}, "equipment": default_equipment(), "shards": default_shards(), "chests": default_chests(), "missions": {"kills": 0, "wins": 0, "claimed_kills": false, "claimed_wins": false}}

func default_equipment() -> Dictionary:
	var result := {}
	for slot in SLOTS:
		result[slot] = {"id": "starter_" + slot, "rarity": 0, "level": 1, "shards": 0, "equipped": true}
	return result

func default_shards() -> Dictionary:
	var result := {}
	for slot in SLOTS:
		result[slot] = 10
	return result

func default_chests() -> Dictionary:
	return {"THƯỜNG": {"free_days": 1, "last_free": "", "gold": 100}, "HIẾM": {"free_days": 2, "last_free": "", "gold": 250}, "HUYỀN THOẠI": {"free_days": 4, "last_free": "", "gold": 600}, "MYTHIC": {"free_days": 7, "last_free": "", "gold": 1500}, "CỔ ĐẠI": {"free_days": 14, "last_free": "", "gold": 3500}}

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
		data.gold = clampi(int(data.gold), 0, 2147483647) if data.gold is float or data.gold is int else 500
		if not data.has("meta_upgrades") or not data.meta_upgrades is Dictionary:
			data.meta_upgrades = defaults().meta_upgrades
		for stat in ["hp", "damage", "armor", "haste"]:
			data.meta_upgrades[stat] = clampi(int(data.meta_upgrades.get(stat, 0)), 0, 20)
		data.upgrade_core = clampi(int(data.upgrade_core), 0, 2147483647) if data.upgrade_core is float or data.upgrade_core is int else 25
		if not data.has("equipment") or not data.equipment is Dictionary:
			data.equipment = default_equipment()
		if not data.has("shards") or not data.shards is Dictionary:
			data.shards = default_shards()
		for slot in SLOTS:
			if not data.equipment.has(slot):
				data.equipment[slot] = default_equipment()[slot]
			if not data.shards.has(slot):
				data.shards[slot] = 10
		if not data.has("chests"):
			data.chests = default_chests()
		if not data.has("missions"):
			data.missions = defaults().missions

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

func add_rewards(gold: int, core: int, slot: String = "", shards: int = 0) -> void:
	data.gold += maxi(0, gold)
	data.upgrade_core += maxi(0, core)
	if slot in SLOTS:
		data.shards[slot] = data.shards.get(slot, 0) + maxi(0, shards)
	save_profile()

func upgrade_meta(stat: String) -> bool:
	if stat not in ["hp", "damage", "armor", "haste"]:
		return false
	var level: int = int(data.meta_upgrades.get(stat, 0))
	var cost := 100 + level * 75
	if data.gold < cost or level >= 20:
		return false
	data.gold -= cost
	data.meta_upgrades[stat] = level + 1
	save_profile()
	return true

func upgrade_equipment(slot: String) -> bool:
	if slot not in SLOTS:
		return false
	var item: Dictionary = data.equipment[slot]
	var level: int = int(item.level)
	var shard_cost: int = 10 + level * 8
	var core_cost: int = 5 + level * 4
	if data.shards[slot] < shard_cost or data.upgrade_core < core_cost or level >= 20:
		return false
	data.shards[slot] -= shard_cost
	data.upgrade_core -= core_cost
	item.level = level + 1
	data.equipment[slot] = item
	save_profile()
	return true

func chest_ready(rarity: String) -> bool:
	var chest: Dictionary = data.chests.get(rarity, {})
	if chest.get("last_free", "") == "":
		return true
	var today: int = Time.get_unix_time_from_system() / 86400
	var opened: int = int(chest.get("last_day", 0))
	return today - opened >= int(chest.get("free_days", 1))

func open_chest(slot: String, rarity_index: int, paid: bool = false) -> Dictionary:
	if slot not in SLOTS:
		return {}
	rarity_index = clampi(rarity_index, 0, RARITIES.size() - 1)
	var rarity: String = RARITIES[rarity_index]
	var chest: Dictionary = data.chests[rarity]
	if paid:
		if data.gold < chest.gold:
			return {}
		data.gold -= chest.gold
	else:
		if not chest_ready(rarity):
			return {}
		chest.last_day = Time.get_unix_time_from_system() / 86400
		chest.last_free = Time.get_date_string_from_system()
	data.chests[rarity] = chest
	var item: Dictionary = data.equipment[slot]
	item.id = "chest_" + rarity.to_lower().replace(" ", "_")
	item.rarity = rarity_index
	item.level = maxi(1, int(item.level))
	item.shards = 0
	data.equipment[slot] = item
	data.shards[slot] += 5 + rarity_index * 5
	save_profile()
	return item.duplicate(true)

func open_chest_with_priority(slot: String, rarity_index: int) -> Dictionary:
	"""Consume the daily free key first, then buy a key with gold."""
	if slot not in SLOTS:
		return {"status": "invalid"}
	rarity_index = clampi(rarity_index, 0, RARITIES.size() - 1)
	var rarity: String = RARITIES[rarity_index]
	if chest_ready(rarity):
		var free_item := open_chest(slot, rarity_index, false)
		return {"status": "free", "item": free_item}
	var chest: Dictionary = data.chests.get(rarity, {})
	var cost: int = int(chest.get("gold", 0))
	if data.gold >= cost:
		var paid_item := open_chest(slot, rarity_index, true)
		return {"status": "gold", "item": paid_item, "cost": cost}
	return {"status": "payment", "cost": cost, "gold": data.gold}

func finish_run(won: bool, seconds: float, kills: int) -> void:
	if practice:
		return
	data.runs += 1
	data.wins += 1 if won else 0
	data.kills += kills
	data.best_seconds = maxf(data.best_seconds, seconds)
	data.missions.kills += kills
	data.missions.wins += 1 if won else 0
	add_rewards(kills * 2, kills, "", 0)
	save_profile()
