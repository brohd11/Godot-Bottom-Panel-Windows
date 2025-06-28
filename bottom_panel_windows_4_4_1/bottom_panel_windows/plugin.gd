@tool

extends EditorPlugin

const control_pairs=[
	["TileMapLayerEditor","TileMap"],
	["TileSetEditor", "TileSet"],
	["EditorLog", "Output"]
]


func _enter_tree() -> void:
	instanced_control_pairs = {}
	Buttons.tile_map(self)
	Buttons.tile_set(self)
	Buttons.editor_log(self)

func _exit_tree() -> void:
	for control_pair in instanced_control_pairs:
		var window_data = instanced_control_pairs.get(control_pair)
	
	Buttons.tile_map(self, true)
	Buttons.tile_set(self, true)
	Buttons.editor_log(self, true)

var tile_map_editor:Control
var tile_set_editor:Control

var tile_map_button:Button
var tile_set_button:Button

var instanced_control_pairs = {}

func _new_window(control_pair:int) -> void:
	var bottom_panel = BottomPanel.get_bottom_panel()
	if control_pair in instanced_control_pairs:
		_on_window_close_requested(control_pair)
		return
	var window = Window.new()
	window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	window.size = Vector2i(1200,800)
	EditorInterface.get_base_control().add_child(window)
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	window.add_child(panel)
	window.close_requested.connect(_on_window_close_requested.bind(control_pair))
	
	var controls = _get_bottom_panel_control(panel, control_pairs[control_pair])
	var editor_panel = controls[0]
	var editor_button = controls[1]
	var window_data = {
		"window": window,
		"panel": editor_panel,
		"button": editor_button,
	}
	instanced_control_pairs[control_pair] = window_data
	if is_instance_valid(editor_panel):
		editor_panel.visibility_changed.connect(_on_visiblity_changed.bind(editor_panel))
	if is_instance_valid(editor_button):
		editor_button.visibility_changed.connect(_on_visiblity_changed.bind(editor_button))


func _on_window_close_requested(control_pair:int) -> void:
	var window_data = instanced_control_pairs.get(control_pair)
	var window = window_data.get("window")
	var editor_panel = window_data.get("panel")
	var editor_button = window_data.get("button")
	var panel = window.get_child(0)
	var control_removed = _remove_bottom_panel_control(panel, control_pairs[control_pair])
	if control_removed:
		window.queue_free()
		if is_instance_valid(editor_panel):
			editor_panel.visibility_changed.disconnect(_on_visiblity_changed)
		if is_instance_valid(editor_button):
			editor_button.visibility_changed.disconnect(_on_visiblity_changed)
		await get_tree().process_frame
		if is_instance_valid(editor_panel):
			editor_panel.hide()
		if is_instance_valid(editor_button):
			editor_button.show()
		
		instanced_control_pairs.erase(control_pair)


func _on_visiblity_changed(control:Control) -> void:
	await get_tree().process_frame
	if control is Button:
		control.visible = false
	else:
		control.visible = true

static func _get_bottom_panel_control(window, control_button_names):
	var control_class = control_button_names[0]
	var button_name = control_button_names[1]
	var bottom_panel = BottomPanel.get_bottom_panel()
	var control = BottomPanel.get_panel(control_class)
	if control:
		var button
		var buttons_hbox = BottomPanel.get_button_hbox()
		for b in buttons_hbox.get_children():
			if b.text == control_button_names[1]:
				if control.visible:
					b.toggled.emit(false)
				button = b
				b.hide()
				break
		control.reparent(window)
		control.show()
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL
		return [control, button]
	else:
		print("Error getting panel %s" % control_class)

static func _remove_bottom_panel_control(window, control_button_names) -> bool:
	var control_class = control_button_names[0]
	var button_name = control_button_names[1]
	for child in window.get_children():
		if child.get_class() == control_button_names[0]:
			var bottom_panel = BottomPanel.get_bottom_panel()
			child.reparent(bottom_panel)
			var buttons_hbox = BottomPanel.get_button_hbox() as HBoxContainer
			for b in buttons_hbox.get_children():
				if b.text == control_button_names[1]:
					b.show()
					break
			var top_hbox = BottomPanel.get_button_top_hbox()
			bottom_panel.move_child(top_hbox, bottom_panel.get_child_count() - 1)
			return true
	return false


class BottomPanel:
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
		var bottom_panel = BottomPanel.get_bottom_panel()
		for p in bottom_panel.get_children():
			if p.get_class() == _class_name:
				return p
		print("Could not find %s" % _class_name)
	
class Buttons:
	static func tile_map(plugin, remove=false):
		var control_pair = 0
		var tile_map = BottomPanel.get_panel(control_pairs[control_pair][0])
		var buttons_target = tile_map.get_child(0)
		_toggle_button(plugin, remove, buttons_target, control_pair)
	
	static func tile_set(plugin, remove=false):
		var control_pair = 1
		var tile_set = BottomPanel.get_panel(control_pairs[control_pair][0])
		var buttons_target = tile_set.get_child(0).get_child(1).get_child(1).get_child(1).get_child(1).get_child(0)
		_toggle_button(plugin, remove, buttons_target, control_pair)
		
	
	static func editor_log(plugin, remove=false):
		var control_pair = 2
		var editor_log = BottomPanel.get_panel(control_pairs[control_pair][0])
		var buttons_target = editor_log.get_child(2)
		_toggle_button(plugin, remove, buttons_target, control_pair)
	
	static func _toggle_button(plugin, remove, button_target, control_pair):
		for child in button_target.get_children():
			if child is Button:
				if child.icon == get_icon():
					if remove:
						child.queue_free()
					return
		var button = new_button()
		button_target.add_child(button)
		button.pressed.connect(plugin._new_window.bind(control_pair))
	
	static func new_button():
		var button = Button.new()
		button.icon = get_icon()
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return button
	
	static func get_icon():
		return EditorInterface.get_editor_theme().get_icon("MakeFloating", &"EditorIcons")
