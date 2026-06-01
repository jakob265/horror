extends Node
# Static definitions for physical inventory items. Mirrors NotesData.
# category drives the tint in the inventory screen:
#   "key" | "tool" | "part" | "fuel" | "consumable" | "misc"

const ALL := {
	"spare_battery": {
		"name": "Spare Battery",
		"category": "consumable",
		"desc": "A cold-stiff lithium cell, half its charge gone. Snaps into the flashlight to reload it.",
	},
	"diesel_can": {
		"name": "Diesel Can",
		"category": "fuel",
		"desc": "A dented jerry can, maybe a third full. The fumes sting your eyes. The generators run on this.",
	},
	"ceramic_fuse": {
		"name": "Ceramic Fuse",
		"category": "part",
		"desc": "A 30-amp ceramic fuse, still intact. Whatever drew through the last one left it black and split.",
	},
	"valve_handle": {
		"name": "Valve Handle",
		"category": "tool",
		"desc": "A heavy iron wheel-handle, pried loose from a bracket. Fits the stripped spindles down in the plant.",
	},
	"bolt_cutters": {
		"name": "Bolt Cutters",
		"category": "tool",
		"desc": "Long-armed cutters, jaws pitted with rust. Built for a chain or a padlock.",
	},
	"dorm_key": {
		"name": "Dormitory Key",
		"category": "key",
		"desc": "A worn brass key on a fob of red tape, marked 'BUNKS' in marker.",
	},
	"signal_flare": {
		"name": "Signal Flare",
		"category": "consumable",
		"desc": "A road flare, cap intact. Burns red and furious for a few minutes. Only one strike in it.",
	},
}


func get_item(id: String) -> Dictionary:
	return ALL.get(id, {})


func name_of(id: String) -> String:
	var d: Dictionary = ALL.get(id, {})
	return d.get("name", id)
