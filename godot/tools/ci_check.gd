extends SceneTree
# CI-only GDScript validator. We have no local Godot, and an exported build
# ships even when an act script has a parse error (the script just fails to
# load at runtime and you fall through the floor - exactly the Act 10 bug). So
# before every export, load (= compile) every .gd and load every .tscn under
# res://. Loading a scene also loads+compiles the scripts attached to it, so a
# parse error anywhere makes load() fail / the engine print "SCRIPT ERROR".
#
#   godot --headless --script res://tools/ci_check.gd
#
# We deliberately do NOT instantiate scenes: instantiate() runs each node's
# _init(), and in --script mode the game's autoload singletons aren't present,
# so that would throw false failures. load() gives us the parse/compile
# coverage we need without executing anything.
#
# Logic lives in _init() (the conventional, reliable entry for a SceneTree tool
# script - quit() latches from here). _process() returning true is a backstop
# so the headless loop can never hang to a CI timeout.

func _init() -> void:
	var files: Array[String] = []
	_walk("res://", files)
	files.sort()
	var failed := 0
	for f in files:
		var res: Resource = load(f)
		if res == null:
			print("CI_CHECK FAIL file=", f)
			failed += 1
	print("CI_CHECK SUMMARY: %d files checked, %d failure(s)." % [files.size(), failed])
	if failed == 0:
		print("CI_CHECK OK")
	quit(1 if failed > 0 else 0)


func _process(_delta: float) -> bool:
	return true


func _walk(path: String, files: Array[String]) -> void:
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
				_walk(full, files)
		elif fname.ends_with(".gd") or fname.ends_with(".tscn"):
			files.append(full)
		fname = d.get_next()
	d.list_dir_end()
