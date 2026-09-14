extends RefCounted
const WEAPONS: Array = [
	preload("res://data/weapons/pulse.tres"),
	preload("res://data/weapons/scatter.tres"),
	preload("res://data/weapons/lance.tres")
]
const CHARACTER_WEAPON_INDEX: Array[int] = [0, 0, 1, 1, 2, 2, 0, 0, 2, 2]

static func weapon_for_character(character_index: int) -> Resource:
	var index := CHARACTER_WEAPON_INDEX[clampi(character_index, 0, CHARACTER_WEAPON_INDEX.size() - 1)]
	return WEAPONS[index]
const ENEMIES: Array = [
	preload("res://data/enemies/chaser.tres"),
	preload("res://data/enemies/runner.tres"),
	preload("res://data/enemies/charger.tres"),
	preload("res://data/enemies/shooter.tres"),
	preload("res://data/enemies/orbiter.tres"),
	preload("res://data/enemies/boss_warden.tres"),
	preload("res://data/enemies/boss_hunter.tres"),
	preload("res://data/enemies/boss_sentinel.tres"),
	preload("res://data/enemies/boss_reaper.tres"),
	preload("res://data/enemies/boss_archon.tres"),
	preload("res://data/enemies/ruby_beetle.tres"),
	preload("res://data/enemies/neon_jackal.tres"),
	preload("res://data/enemies/amber_ram.tres"),
	preload("res://data/enemies/void_spitter.tres"),
	preload("res://data/enemies/blade_mantis.tres"),
	preload("res://data/enemies/needle_walker.tres"),
	preload("res://data/enemies/forge_crab.tres"),
	preload("res://data/enemies/storm_jelly.tres"),
	preload("res://data/enemies/rift_scorpion.tres"),
	preload("res://data/enemies/sword_automaton.tres"),
	preload("res://data/enemies/spore_carrier.tres"),
	preload("res://data/enemies/blood_harpy.tres"),
	preload("res://data/enemies/ghost_centipede.tres"),
	preload("res://data/enemies/prism_golem.tres"),
	preload("res://data/enemies/crown_serpent.tres")
]
const UPGRADES: Array = [
	preload("res://data/upgrades/power.tres"), preload("res://data/upgrades/tempo.tres"),
	preload("res://data/upgrades/stride.tres"), preload("res://data/upgrades/vitality.tres"),
	preload("res://data/upgrades/repair.tres"), preload("res://data/upgrades/pierce.tres"),
	preload("res://data/upgrades/velocity.tres"), preload("res://data/upgrades/reach.tres"),
	preload("res://data/upgrades/armor.tres"), preload("res://data/upgrades/recovery.tres"),
	preload("res://data/upgrades/echo_power.tres"), preload("res://data/upgrades/multishot.tres"),
	preload("res://data/upgrades/critical.tres"), preload("res://data/upgrades/siphon.tres"),
	preload("res://data/upgrades/shield.tres")
]
const SECONDARY_WEAPONS: Array = [
	preload("res://data/upgrades/secondary_boomerang.tres"),
	preload("res://data/upgrades/secondary_orbit.tres"),
	preload("res://data/upgrades/secondary_drone.tres"),
	preload("res://data/upgrades/secondary_mine.tres"),
	preload("res://data/upgrades/secondary_beam.tres")
]
const MAPS: Array = [
	preload("res://data/maps/neon_ruins.tres"),
	preload("res://data/maps/crystal_basin.tres"),
	preload("res://data/maps/iron_foundry.tres"),
	preload("res://data/maps/void_garden.tres"),
	preload("res://data/maps/frost_station.tres"),
	preload("res://data/maps/solar_grid.tres"),
	preload("res://data/maps/storm_atlas.tres"),
	preload("res://data/maps/black_archive.tres"),
	preload("res://data/maps/red_frontier.tres"),
	preload("res://data/maps/replay_core.tres")
]
