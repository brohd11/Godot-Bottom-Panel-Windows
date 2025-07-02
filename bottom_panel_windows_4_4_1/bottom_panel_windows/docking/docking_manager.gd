@tool
extends RefCounted

const Docks = preload("uid://c2jrte1t34vo") #>import docks.gd
const MainScreen = preload("uid://bt716u3s7bxbu") #>import main_screen.gd
const BottomPanel = preload("uid://k31vw0igra2p") #>import bottom_panel.gd

var plugin:EditorPlugin

var tracked_control_data = {}

func _init(_plugin:EditorPlugin) -> void:
	plugin = _plugin

func return_controls():
	for control_pair in tracked_control_data.keys():
		var control_data = tracked_control_data.get(control_pair)
		var home = control_data.get(ControlData.home)
		var control = control_data.get(ControlData.control)
		dock_instance(home, control_pair)
		control.hide()


func dock_instance(target_dock:int, control_pair):
	var control_data = tracked_control_data.get(control_pair)
	var control = control_data.get(ControlData.control)
	
	var window = control.get_window()
	var current_dock = control_data.get(ControlData.current_dock)
	var control_parent = control.get_parent()
	if current_dock == -3:
		control_parent.remove_child(control)
	elif current_dock == -2:
		control_parent.remove_child(control)
	elif current_dock == -1:
		pass
	else:
		if control_parent is DockWrapper:
			plugin.remove_control_from_docks(control_parent)
			control_parent.remove_child(control)
		else:
			plugin.remove_control_from_docks(control)
	if control_parent is DockWrapper:
		control_parent.queue_free()
	
	var button = control_data.get(ControlData.button)
	_connect_vis_signals(control, control_pair)
	_connect_vis_signals(button, control_pair)
	var home = control_data.get(ControlData.home)
	if home == target_dock:
		_disconnect_vis_signals(control)
		_disconnect_vis_signals(button)
	if target_dock > -1:
		button.toggled.emit(false)
		button.hide()
		var dock_wrapper = DockWrapper.new()
		dock_wrapper.add_child(control)
		dock_wrapper.name = control.name
		plugin.add_control_to_dock(target_dock, dock_wrapper)
		control.show()
	elif target_dock == -2:
		if home == target_dock:
			return_bottom_panel_control(control, button)
			tracked_control_data.erase(control_pair)
			await plugin.get_tree().process_frame
			button.show()
			control.hide()
		else:
			var name = control_data.get("name")
			plugin.add_control_to_bottom_panel(control, name)
	
	control_data[ControlData.current_dock] = target_dock
	
	if is_instance_valid(window):
		if window is PanelWindow:
			window.queue_free()


func undock_instance(control_pair):
	var control_data = tracked_control_data.get(control_pair)
	var control = control_data.get(ControlData.control)
	var button = control_data.get(ControlData.button)
	button.toggled.emit(false)
	button.hide()
	var current_dock = get_current_dock(control)
	_connect_vis_signals(control, control_pair)
	_connect_vis_signals(button, control_pair)
	var control_parent = control.get_parent()
	var control_to_remove = control
	if control_parent is DockWrapper:
		control_to_remove = control_parent
	if current_dock > -1:
		plugin.remove_control_from_docks(control_to_remove)
	else:
		pass
	
	control_data[ControlData.current_dock] = -3
	var window = PanelWindow.new(control)
	window.close_requested.connect(window_close_requested.bind(control_pair))
	
	window.mouse_entered.connect(_on_window_mouse_entered.bind(window))
	window.mouse_exited.connect(_on_window_mouse_exited)
	
	if control_parent is DockWrapper:
		control_parent.queue_free()
	return window


static func return_bottom_panel_control(control, button):
	var bottom_panel = BottomPanel.get_bottom_panel()
	bottom_panel.add_child(control)
	button.show()
	var top_hbox = BottomPanel.get_button_top_hbox()
	bottom_panel.move_child(top_hbox, bottom_panel.get_child_count() - 1)


func _connect_vis_signals(control, control_pair):
	if not control.visibility_changed.is_connected(visibility_changed):
		control.visibility_changed.connect(visibility_changed.bind(control, control_pair))

func _disconnect_vis_signals(control:Control):
	control.visibility_changed.disconnect(visibility_changed)


func visibility_changed(control:Control, control_pair) -> void:
	if not control.is_inside_tree():
		return
	await control.get_tree().process_frame
	if control is Button:
		control.visible = false
	else:
		control.visible = true

func window_close_requested(control_pair:int) -> void:
	dock_instance(-2, control_pair)

func _on_window_mouse_entered(window):
	window.grab_focus()

func _on_window_mouse_exited():
	EditorInterface.get_base_control().get_window().grab_focus()

static func get_current_dock(control):
	var parent = control.get_parent()
	if not parent:
		print("Parent is null.")
		return
	if parent is DockWrapper:
		parent = parent.get_parent()
	
	if parent == Docks.get_left_ul():
		return EditorPlugin.DockSlot.DOCK_SLOT_LEFT_UL
	elif parent == Docks.get_left_bl():
		return EditorPlugin.DockSlot.DOCK_SLOT_LEFT_BL
	elif parent == Docks.get_left_ur():
		return EditorPlugin.DockSlot.DOCK_SLOT_LEFT_UR
	elif parent == Docks.get_left_br():
		return EditorPlugin.DockSlot.DOCK_SLOT_LEFT_BR
	elif parent == Docks.get_right_ul():
		return EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_UL
	elif parent == Docks.get_right_bl():
		return EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_BL
	elif parent == Docks.get_right_ur():
		return EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_UR
	elif parent == Docks.get_right_br():
		return EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_BR
	elif parent == BottomPanel.get_bottom_panel():
		return -2
	elif parent == MainScreen.get_main_screen():
		return -1
	else:
		return -3

static func get_current_dock_control(control):
	var parent = control.get_parent()
	if not parent:
		print("Parent is null.")
		return
	if parent is DockWrapper:
		return parent.get_parent()
	elif parent is TabContainer:
		return parent
	elif parent == BottomPanel.get_bottom_panel():
		return parent
	elif parent == MainScreen.get_main_screen():
		return parent


class PanelWindow extends Window: #>class
	func _init(control) -> void:
		initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
		size = Vector2i(1200,800)
		EditorInterface.get_base_control().add_child(self)
		var panel = PanelContainer.new()
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(panel)
		always_on_top = true
		
		if is_instance_valid(control.get_parent()):
			control.reparent(panel)
		else:
			panel.add_child(control)
		
		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		control.show()

class FloatButton extends HBoxContainer:
	var button: Button
	var menu_button: Button
	const MENU_OPTIONS = [
		"BOTTOM_PANEL",
		#"MAIN_SCREEN",
		"SKIP",
		"DOCK_SLOT_LEFT_UL",
		"DOCK_SLOT_LEFT_BL",
		"DOCK_SLOT_LEFT_UR",
		"DOCK_SLOT_LEFT_BR",
		"DOCK_SLOT_RIGHT_UL",
		"DOCK_SLOT_RIGHT_BL",
		"DOCK_SLOT_RIGHT_UR",
		"DOCK_SLOT_RIGHT_BR",
	]
	func _init():
		add_theme_constant_override("seperation", 0)
		button = Button.new()
		add_child(button)
		button.icon = get_icon()
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.flat = true
		button.hide()
		menu_button = Button.new()
		menu_button.icon = button.icon
		menu_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		menu_button.flat = true
		menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		menu_button.focus_mode = Control.FOCUS_NONE
		add_child(menu_button)
	
	static func get_icon():
		return EditorInterface.get_editor_theme().get_icon("MakeFloating", &"EditorIcons")

class DockWrapper extends VBoxContainer: #>class
	func _init() -> void:
		add_theme_constant_override("seperation", 0)

class ControlData: #>class
	const home = "home"
	const control = "control"
	const button = "button"
	const popup_button = "popup_button"
	const current_dock = "current_dock"
	const current_dock_index = "current_dock_index"
	#const last_visibility = "last_visibility"
