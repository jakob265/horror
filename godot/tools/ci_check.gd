extends SceneTree
# CI-only GDScript validator. We have no local Godot, and an exported build
# happily ships even when an act script has a parse error (the script just
# fails to load at runtime and you fall through the floor - exactly the Act 10
# bug). So before every export, load + compile every .gd and load + instantiate
# every .tscn here. A parse/compile error prints "SCRIPT ERROR"/"Parse Error"
# to stderr (grepped by the workflow), and a hard failure trips CHECK FAIL +
# a non-zero exit below.
#
#   godot --headless --script res://tools/ci_check.gd
#
# instantiate() builds the node tree and attaches (thus compiles) every script
# WITHOUT adding it to the SceneTree, so _ready()/_enter_tree() never run - we
# validate structure and parsing, not gameplay (no player/autoload wiring
# needed).

func _init() -> void:
	var scripts: Array[String] = []
	var scenes: Array[String] = []
	_walk("res://", scripts, scenes)
	scripts.sort()
	scenes.sort()
	var failed := 0

	for s in scripts:
		var res: Resource = load(s)
		if res == null:
			print("CHECK FAIL (script load): ", s)
			failed += 1

	for sc in scenes:
		var packed = load(sc)
		if packed == null:
			print("CHECK FAIL (scene load): ", sc)
			failed += 1
			continue
		var inst = packed.instantiate()
		if inst == null:
			print("CHECK FAIL (instantiate): ", sc)
			failed += 1
		else:
			inst.free()

	print("ci_check: %d scripts, %d scenes checked, %d failure(s)." % [scripts.size(), scenes.size(), failed])
	quit(1 if failed > 0 else 0)


func _walk(path: String, scripts: Array[String], scenes: Array[String]) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	d.list_dir_begin()
	var fname := d.get_next()
	while fname != "":
		if fname.begins_with("."):
			fname = d.get_next()
			continue
		var full := path.path_join(fname)
		if d.current_is_dir():
			if fname != "addons":
				_walk(full, scripts, scenes)
		elif fname.ends_with(".gd"):
			scripts.append(full)
		elif fname.ends_with(".tscn"):
			scenes.append(full)
		fname = d.get_next()
	d.list_dir_end()
