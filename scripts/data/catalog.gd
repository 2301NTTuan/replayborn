extends RefCounted

const WEAPONS: Array[Resource] = [
	preload("res://data/weapons/pulse.tres"), preload("res://data/weapons/scatter.tres"), preload("res://data/weapons/lance.tres")
]
const REGULAR_ENEMIES: Array[Resource] = [
	preload("res://data/enemies/ruby_beetle.tres"), preload("res://data/enemies/neon_jackal.tres"), preload("res://data/enemies/amber_ram.tres"),
	preload("res://data/enemies/void_spitter.tres"), preload("res://data/enemies/blade_mantis.tres"), preload("res://data/enemies/needle_walker.tres"),
	preload("res://data/enemies/forge_crab.tres"), preload("res://data/enemies/storm_jelly.tres"), preload("res://data/enemies/rift_scorpion.tres"),
	preload("res://data/enemies/sword_automaton.tres"), preload("res://data/enemies/spore_carrier.tres"), preload("res://data/enemies/blood_harpy.tres"),
	preload("res://data/enemies/ghost_centipede.tres"), preload("res://data/enemies/prism_golem.tres"), preload("res://data/enemies/crown_serpent.tres")
]
const BOSSES: Array[Resource] = [
	preload("res://data/enemies/boss_warden.tres"), preload("res://data/enemies/boss_hunter.tres"), preload("res://data/enemies/boss_sentinel.tres"), preload("res://data/enemies/boss_reaper.tres"), preload("res://data/enemies/boss_archon.tres")
]
const ENEMIES: Array[Resource] = REGULAR_ENEMIES + BOSSES
const UPGRADES: Array[Resource] = [
	preload("res://data/upgrades/power.tres"), preload("res://data/upgrades/tempo.tres"), preload("res://data/upgrades/stride.tres"), preload("res://data/upgrades/vitality.tres"), preload("res://data/upgrades/armor.tres"), preload("res://data/upgrades/recovery.tres"),
	preload("res://data/upgrades/long_memory.tres"), preload("res://data/upgrades/wide_recall.tres"), preload("res://data/upgrades/circuit_power.tres"), preload("res://data/upgrades/time_lock.tres"), preload("res://data/upgrades/safe_closure.tres"), preload("res://data/upgrades/compression.tres"),
	preload("res://data/upgrades/pulse_relay.tres"), preload("res://data/upgrades/pulse_overload.tres"), preload("res://data/upgrades/scatter_focus.tres"), preload("res://data/upgrades/scatter_shrapnel.tres"), preload("res://data/upgrades/lance_resonance.tres"), preload("res://data/upgrades/lance_collapse.tres")
]
const MAPS: Array[Resource] = [
	preload("res://data/maps/neon_ruins.tres"), preload("res://data/maps/black_archive.tres"), preload("res://data/maps/solar_grid.tres"), preload("res://data/maps/void_garden.tres"), preload("res://data/maps/replay_core.tres")
]
const LEVELS: Array[Resource] = [
	preload("res://data/levels/signal_gate.tres"), preload("res://data/levels/fractured_lane.tres"), preload("res://data/levels/static_array.tres"), preload("res://data/levels/orbit_vault.tres"), preload("res://data/levels/replay_core.tres")
]

static func selected_weapon(index: int) -> Resource:
	return WEAPONS[clampi(index, 0, WEAPONS.size() - 1)]

static func enemy_by_id(id: String) -> Resource:
	for enemy in ENEMIES:
		if String(enemy.id) == id:
			return enemy
	return null

static func regular_enemy_by_id(id: String) -> Resource:
	for enemy in REGULAR_ENEMIES:
		if String(enemy.id) == id:
			return enemy
	return null

static func boss_by_id(id: String) -> Resource:
	for boss in BOSSES:
		if String(boss.id) == id:
			return boss
	return null

static func map_by_id(id: String) -> Resource:
	for map_data in MAPS:
		if String(map_data.id) == id:
			return map_data
	return MAPS[0]
