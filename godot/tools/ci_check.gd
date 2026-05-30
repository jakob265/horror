extends SceneTree
# CI-only GDScript validator. We have no local Godot, and an exported build
# happily ships even when an act script has a parse error (the script just
# fails to load at runtime and you fall through the floor - exactly the Act 10
# bug). So before every export, load + compile every .gd and load + instantiate
# every .tscn here.
#
#   godot --headless --script res://tools/ci_check.gd
#
# instantiate() builds the node tree and attaches (thus compiles) every script
# WITHOUT adding it to the SceneTree, so _ready()/_enter_tree() never run - we
# validate structure and parsing, not gameplay (no player/autoload wiring
# needed). A parse error makes the engine print "SCRIPT ERROR"/"Parse Error" to
# stderr; we additionally print a self-describing "CI_CHECK FAIL ... file=..."
# line per failure and exit non-zero, and the workflow promotes those lines to
# GitHub error annotations so the failing file is visible without raw logs.
#
# Lifecycle note: for a SceneTree main-loop script, _initialize() is the
# canonical entry point (not _init(), where quit() may not latch and the
# headless loop can hang until CI times out). _process() returning true is a
# belt-and-suspenders guarantee the loop terminates after one frame.

var _exit_code := 0


func _initialize() -> void:
	var scripts: Array[String] = []
	var scenes: Array[String] = []
	_walk("res://", scripts, scenes)
	scripts.sort()
	scenes.sort()
	var failed := 0

	for s in scripts:
		var res: Resource = load(s)
		if res == null:
			print("CI_CHECK FAIL (script load) file=", s)
			failed += 1

	for sc in scenes:
		var packed = load(sc)
		if packed == null:
			print("CI_CHECK FAIL (scene load) file=", sc)
			failed += 1
			continue
		var inst = packed.instantiate()
		if inst == null:
			print("CI_CHECK FAIL (instantiate) file=", sc)
			failed += 1
		else:
			inst.free()

	print("CI_CHECK SUMMARY: %d scripts, %d scenes checked, %d failure(s)." % [scripts.size(), scenes.size(), failed])
	if failed == 0:
		print("CI_CHECK OK")
	_exit_code = 1 if failed > 0 else 0
	quit(_exit_code)


# Guarantees the headless main loop exits even if quit() above is deferred.
func _process(_delta: float) -> bool:
	return true


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
