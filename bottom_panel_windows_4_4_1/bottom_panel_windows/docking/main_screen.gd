extends RefCounted

static func get_main_screen():
	return EditorInterface.get_editor_main_screen()

static func get_title_bar():
	return EditorInterface.get_base_control().get_child(0).get_child(0)
	
static func get_button_container():
	return get_title_bar().get_child(2)

static func get_button_theme():
	var button = get_title_bar().get_child(2).get_child(0) as Button
	return button.theme_type_variation
