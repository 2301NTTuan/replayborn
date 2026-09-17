extends RefCounted
const WEAPONS: Array = [
	preload("res://data/weapons/pulse.tres"),
	preload("res://data/weapons/scatter.tres"),
	preload("res://data/weapons/lance.tres")
]
static func selected_weapon(index: int) -> Resource:
	return WEAPONS[clampi(index, 0, WEAPONS.size() - 1)]
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
	preload("res://data/enemies/boss_archon.tres")
]
const UPGRADES: Array = [
	preload("res://data/upgrades/power.tres"), preload("res://data/upgrades/tempo.tres"),
	preload("res://data/upgrades/stride.tres"), preload("res://data/upgrades/vitality.tres"),
	preload("res://data/upgrades/armor.tres"), preload("res://data/upgrades/recovery.tres"),
	preload("res://data/upgrades/long_memory.tres"), preload("res://data/upgrades/wide_recall.tres"),
	preload("res://data/upgrades/circuit_power.tres"), preload("res://data/upgrades/time_lock.tres"),
	preload("res://data/upgrades/safe_closure.tres"), preload("res://data/upgrades/compression.tres"),
	preload("res://data/upgrades/pulse_relay.tres"), preload("res://data/upgrades/pulse_overload.tres"),
	preload("res://data/upgrades/scatter_focus.tres"), preload("res://data/upgrades/scatter_shrapnel.tres"),
	preload("res://data/upgrades/lance_resonance.tres"), preload("res://data/upgrades/lance_collapse.tres")
]
const MAPS: Array = [preload("res://data/maps/neon_ruins.tres")]
const LEVELS: Array = [
	preload("res://data/levels/signal_gate.tres"),
	preload("res://data/levels/fractured_lane.tres"),
	preload("res://data/levels/static_array.tres"),
	preload("res://data/levels/orbit_vault.tres"),
	preload("res://data/levels/replay_core.tres")
]
