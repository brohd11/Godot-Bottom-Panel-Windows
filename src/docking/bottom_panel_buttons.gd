@tool
extends RefCounted

const DOCKING_MANAGER = preload("res://addons/bottom_panel_windows/src/docking/bottom_panel_docking_manager.gd") #>import docking_manager.gd
const EditorNodes = preload("res://addons/bottom_panel_windows/src/bottom_panel_editor_nodes.gd") #>import editor_nodes.gd
const BottomPanel = EditorNodes.BottomPanel #>remote

static var control_pairs = [
	["TileMapLayerEditor","TileMap", tile_map, "TileMapLayer"],
	["TileSetEditor", "TileSet", tile_set, "TileSet"],
	["EditorLog", "Output", editor_log],
	["EditorAudioBuses","Audio", audio, "AudioBusLayout"],
	#["AnimationPlayerEditor", "Animation", animation, "Animation"], # throws errors
	["AnimationTreeEditor", "AnimationTree", animation_tree, "AnimationTree"],
	["SpriteFramesEditor", "SpriteFrames", sprite_frames, "SpriteFrames"],
	["FindInFilesPanel", "Search Results", find_in_files, "Search"],
	["GridMapEditor", "GridMap", grid_map, "GridMap"]
]

static var float_buttons = {}

static func add_buttons(plugin):
	for i in range(control_pairs.size()):
		var data = control_pairs[i]
		var callable = data[2]
		callable.call(plugin, i)

static func remove_buttons(plugin):
	for i in range(control_pairs.size()):
		var data = control_pairs[i]
		var callable = data[2]
		callable.call(plugin, i, true)

static func tile_map(plugin, control_pair, remove=false):
	var tile_map = BottomPanel.get_panel(control_pairs[control_pair][0])
	var buttons_target = tile_map.get_child(0)
	_toggle_button(plugin, remove, buttons_target, control_pair)

static func tile_set(plugin, control_pair, remove=false):
	var tile_set = BottomPanel.get_panel(control_pairs[control_pair][0])
	var buttons_target = tile_set.get_child(0).get_child(1).get_child(1).get_child(1).get_child(1).get_child(0)
	_toggle_button(plugin, remove, buttons_target, control_pair)

static func editor_log(plugin, control_pair, remove=false):
	var editor_log = BottomPanel.get_panel(control_pairs[control_pair][0])
	var buttons_target = editor_log.get_child(2)
	_toggle_button(plugin, remove, buttons_target, control_pair, true)

static func audio(plugin, control_pair, remove=false):
	var audio = BottomPanel.get_panel(control_pairs[control_pair][0])
	var buttons_target = audio.get_child(0)
	_toggle_button(plugin, remove, buttons_target, control_pair)

static func animation(plugin, control_pair, remove=false):
	var animation = BottomPanel.get_panel(control_pairs[control_pair][0])
	var buttons_target = animation.get_child(0)
	_toggle_button(plugin, remove, buttons_target, control_pair)

static func animation_tree(plugin, control_pair, remove=false):
	var animation_tree = BottomPanel.get_panel(control_pairs[control_pair][0])
	var buttons_target = animation_tree.get_child(0).get_child(0)
	_toggle_button(plugin, remove, buttons_target, control_pair)

static func sprite_frames(plugin, control_pair, remove=false):
	var sprite_frames = BottomPanel.get_panel(control_pairs[control_pair][0])
	var buttons_target = sprite_frames.get_child(2).get_child(1).get_child(0).get_child(0)
	_toggle_button(plugin, remove, buttons_target, control_pair)

static func find_in_files(plugin, control_pair, remove=false):
	var find_in_files = BottomPanel.get_panel(control_pairs[control_pair][0])
	var buttons_target = find_in_files.get_child(1).get_child(0)
	_toggle_button(plugin, remove, buttons_target, control_pair)

static func grid_map(plugin, control_pair, remove=false):
	var grid_map = BottomPanel.get_panel(control_pairs[control_pair][0])
	var buttons_target = grid_map.get_child(1)
	_toggle_button(plugin, remove, buttons_target, control_pair)

static func _toggle_button(plugin, remove, button_target, control_pair, move_to_front=false):
	for child in button_target.get_children():
		if child is DOCKING_MANAGER.FloatButton:
			if remove:
				child.queue_free()
				float_buttons.erase(control_pair)
			return
	if remove:
		return
	var float_button = DOCKING_MANAGER.FloatButton.new()
	button_target.add_child(float_button)
	float_button.button.pressed.connect(plugin._open_dock_popup.bind(control_pair, float_button))
	if move_to_front:
		button_target.move_child(float_button, 0)
	float_buttons[control_pair] = float_button

static func set_bottom_panel_icons(clear=false):
	return
	var editor_settings = EditorInterface.get_editor_settings()
	var icon_setting = editor_settings.get("interface/editor/dock_tab_style")
	
	var bottom_panel_hbox = BottomPanel.get_button_hbox()
	var bottom_buttons = bottom_panel_hbox.get_children()
	for i in range(control_pairs.size()):
		var data = control_pairs[i]
		if data.size() < 4:
			continue
		var button_name = data[1]
		var button_icon = data[3]
		for button in bottom_buttons:
			if not button is Button:
				continue
			
			if button.text == button_name:
				if clear or icon_setting == 0:
					button.icon = null
				else:
					button.icon = EditorInterface.get_editor_theme().get_icon(button_icon, &"EditorIcons")
