# Quick check: do autoloads work in --script mode?
extends SceneTree
func _init() -> void:
	var sep = "============================================================"
	print(sep)
	print("TEST: Autoload check in --script mode")
	print(sep)
	print("root children count: ", root.get_child_count())
	for i in range(root.get_child_count()):
		var c = root.get_child(i)
		print("  child[", i, "]: name=", c.name, " script=", c.get_script())
	quit()
