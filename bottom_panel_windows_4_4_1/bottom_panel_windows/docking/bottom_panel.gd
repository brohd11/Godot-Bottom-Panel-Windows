extends RefCounted


static func get_bottom_panel() -> Control:
	var base = EditorInterface.get_base_control()
	var bp = base.get_child(0).get_child(1).get_child(1).get_child(1).get_child(0).get_child(0).get_child(1)
	var vbox = bp.get_child(0)
	return vbox

static func get_button_top_hbox():
	var bp = get_bottom_panel()
	var bp_children = bp.get_children()
	bp_children.reverse()
	var hbox = null
	for control in bp_children:
		var nested_children = control.get_children()
		for nc in nested_children:
			if nc.get_class() == "EditorToaster":
				hbox = control
				break
		if is_instance_valid(hbox):
			break
	return hbox

static func get_button_hbox():
	var hbox = get_button_top_hbox()
	var buttons_hbox = hbox.get_child(1).get_child(0, true)
	return buttons_hbox

static func get_panel(_class_name):
	var bottom_panel = get_bottom_panel()
	for p in bottom_panel.get_children():
		if p.get_class() == _class_name:
			return p
	push_error("Could not find %s" % _class_name)
