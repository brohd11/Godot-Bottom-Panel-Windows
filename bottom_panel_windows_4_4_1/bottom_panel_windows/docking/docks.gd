extends RefCounted

static func get_left_h_split():
	var split = EditorInterface.get_base_control().get_child(0).get_child(1)
	return split

static func get_left_ul() -> TabContainer:
	var split = get_left_h_split()
	var tab = split.get_child(0).get_child(0)
	return tab

static func get_left_bl():
	var split = get_left_h_split()
	var tab = split.get_child(0).get_child(1)
	return tab

static func get_left_ur():
	var split = get_left_h_split()
	var tab = split.get_child(1).get_child(0).get_child(0)
	return tab

static func get_left_br():
	var split = get_left_h_split()
	var tab = split.get_child(1).get_child(0).get_child(1)
	return tab

static func get_right_h_split():
	var left_split = get_left_h_split()
	var split = left_split.get_child(1).get_child(1).get_child(1)
	return split

static func get_right_ul():
	var split = get_right_h_split()
	var tab = split.get_child(0).get_child(0)
	return tab

static func get_right_bl():
	var split = get_right_h_split()
	var tab = split.get_child(0).get_child(1)
	return tab

static func get_right_ur():
	var split = get_right_h_split()
	var tab = split.get_child(1).get_child(0)
	return tab

static func get_right_br():
	var split = get_right_h_split()
	var tab = split.get_child(1).get_child(1)
	return tab
