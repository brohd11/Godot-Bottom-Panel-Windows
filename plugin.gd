@tool
extends EditorPlugin

#const LAYOUT_FILE = "res://addons/bottom_panel_windows/config/layout.json"
const DOCKING_MANAGER = preload("uid://b1bk6fs0vs68d") # bottom_panel_docking_manager.gd
const ControlData = DOCKING_MANAGER.ControlData

const Utils = preload("uid://fyxjpywx3oml") # bottom_panel_utils.gd
const EditorNodes = preload("uid://bcwlh7el7hhbs") # bottom_panel_editor_nodes.gd
const Buttons = preload("uid://d34qsa4mbfpwc") #>import bottom_panel_buttons.gd
const BottomPanel = EditorNodes.BottomPanel #>remote
const Docks = EditorNodes.Docks #>remote
const DockPopupHandler = Utils.DockPopupHandler #>remote

var layout_file_path:String = ""
var DockingManager:DOCKING_MANAGER #>class_inst

var _init_flag := false

func _enter_tree() -> void:
	layout_file_path = _get_layout_file_path()
	
	DockingManager = DOCKING_MANAGER.new(self)
	Buttons.add_buttons(self)
	
	if not FileAccess.file_exists(layout_file_path):
		Utils.UFile.write_to_json({}, layout_file_path)
	else:
		await get_tree().process_frame
		var layout_data = Utils.UFile.read_from_json(layout_file_path)
		for control_pair in layout_data:
			var saved_control_data = layout_data.get(control_pair)
			control_pair = int(control_pair)
			var float_button = Buttons.float_buttons.get(control_pair)
			get_control_data(control_pair, float_button)
			var current_dock_index = saved_control_data.get(ControlData.current_dock_index, -5)
			
			var target_dock = saved_control_data.get(ControlData.current_dock)
			if target_dock != -3:
				DockingManager.dock_instance(target_dock, control_pair)
			else:
				DockingManager.undock_instance(control_pair)
			if target_dock < 0:
				continue
			if current_dock_index == -5:
				continue
			var new_control_data = DockingManager.tracked_control_data.get(control_pair)
			var control = new_control_data.get(ControlData.control)
			var dock_wrapper = control.get_parent()
			var dock = DockingManager.get_current_dock_control(control) as TabContainer
			if not current_dock_index < dock.get_tab_count():
				current_dock_index = dock.get_tab_count() - 1
			dock.move_child(dock_wrapper, current_dock_index)
	
	Buttons.set_bottom_panel_icons()
	_init_flag = true

func _get_layout_file_path():
	var dir = get_script().resource_path.get_base_dir()
	var layout_path = dir.path_join(".bottom_panel_windows/layout.json")
	if not DirAccess.dir_exists_absolute(layout_path.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(layout_path.get_base_dir())
	return layout_path


func _exit_tree() -> void:
	_save_layout()
	DockingManager.return_controls()
	DockingManager = null
	Buttons.remove_buttons(self)
	
	Buttons.set_bottom_panel_icons(true)


func _get_window_layout(configuration: ConfigFile) -> void: #TODO, set up save system
	if not _init_flag:
		return
	_save_layout()

func _save_layout():
	layout_file_path = _get_layout_file_path()
	if not is_instance_valid(DockingManager):
		return
	for control_pair in DockingManager.tracked_control_data.keys():
		var control_data = DockingManager.tracked_control_data.get(control_pair)
		var control = control_data.get(ControlData.control)
		var current_dock = DockingManager.get_current_dock(control)
		if current_dock == null:
			current_dock = -3
		control_data[ControlData.current_dock] = current_dock
		var current_dock_control = DockingManager.get_current_dock_control(control)
		
		var current_dock_index = 0
		if current_dock_control is TabContainer:
			var dock_wrapper = control.get_parent()
			current_dock_index = current_dock_control.get_tab_idx_from_control(dock_wrapper)
		control_data[ControlData.current_dock_index] = current_dock_index
		DockingManager.tracked_control_data[control_pair] = control_data
	
	Utils.UFile.write_to_json(DockingManager.tracked_control_data, layout_file_path)

func get_control_data(control_pair:int, float_button:DOCKING_MANAGER.FloatButton) -> void:
	var bottom_panel = BottomPanel.get_bottom_panel()
	var controls = _get_bottom_panel_control(Buttons.control_pairs[control_pair])
	var editor_panel = controls[0]
	editor_panel.name = Buttons.control_pairs[control_pair][0]
	var editor_button = controls[1]
	var control_data = {
		ControlData.home: -2,
		ControlData.control: editor_panel,
		ControlData.button: editor_button,
		ControlData.popup_button: float_button,
		ControlData.current_dock: -2,
	}
	
	DockingManager.tracked_control_data[control_pair] = control_data


func _open_dock_popup(control_pair:int, float_button:DOCKING_MANAGER.FloatButton):
	if not control_pair in DockingManager.tracked_control_data.keys():
		get_control_data(control_pair, float_button)
	var control_data = DockingManager.tracked_control_data.get(control_pair)
	var current_dock = control_data.get(ControlData.current_dock)
	await get_tree().process_frame
	var dock_popup_handler:DockPopupHandler = DockPopupHandler.new(float_button)
	dock_popup_handler.disable_main_screen()
	
	var handled = await dock_popup_handler.handled
	if handled is String:
		return
	if handled == current_dock:
		var home = control_data.get(ControlData.home)
		if home == current_dock:
			DockingManager.tracked_control_data.erase(control_pair)
		return
	
	if handled == -3:
		DockingManager.undock_instance(control_pair)
		return
	
	DockingManager.dock_instance(handled, control_pair)

func _get_bottom_panel_control(control_button_names):
	var control_class = control_button_names[0]
	var button_name = control_button_names[1]
	var bottom_panel = BottomPanel.get_bottom_panel()
	var control = BottomPanel.get_panel(control_class)
	if control:
		var button
		var buttons_hbox = BottomPanel.get_button_hbox()
		for b in buttons_hbox.get_children():
			if b.text == control_button_names[1]:
				button = b
				break
		return [control, button]
	else:
		print("Error getting panel %s" % control_class)
