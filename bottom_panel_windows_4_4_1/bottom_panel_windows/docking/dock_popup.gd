@tool
extends PopupPanel

const CANCEL_STRING = "CANCEL_STRING"

@onready var left_ul: Button = %LeftUL
@onready var left_bl: Button = %LeftBL
@onready var left_ur: Button = %LeftUR
@onready var left_br: Button = %LeftBR
@onready var main_screen: Button = %MainScreen
@onready var bottom_panel: Button = %BottomPanel
@onready var right_ul: Button = %RightUL
@onready var right_bl: Button = %RightBL
@onready var right_ur: Button = %RightUR
@onready var right_br: Button = %RightBR
@onready var make_floating_button: Button = %MakeFloatingButton

var timer:Timer
var _mouse_in_panel := true

var option_chosen := false

signal handled(arg)

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	popup_hide.connect(_on_popup_hide)
	
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.8
	timer.one_shot = true
	
	left_ul.pressed.connect(_button_pressed.bind(0))
	left_bl.pressed.connect(_button_pressed.bind(1))
	left_ur.pressed.connect(_button_pressed.bind(2))
	left_br.pressed.connect(_button_pressed.bind(3))
	main_screen.pressed.connect(_button_pressed.bind(-1))
	bottom_panel.pressed.connect(_button_pressed.bind(-2))
	right_ul.pressed.connect(_button_pressed.bind(4))
	right_bl.pressed.connect(_button_pressed.bind(5))
	right_ur.pressed.connect(_button_pressed.bind(6))
	right_br.pressed.connect(_button_pressed.bind(7))
	
	make_floating_button.pressed.connect(_button_pressed.bind(-3))
	
	make_floating_button.icon = EditorInterface.get_editor_theme().get_icon("MakeFloating", &"EditorIcons")

func disable_main_screen():
	main_screen.disabled = true

func hide_make_floating():
	size.y = size.y - make_floating_button.size.y
	make_floating_button.hide()
	

func _button_pressed(chosen):
	option_chosen = true
	handled.emit(chosen)
	queue_free()

func _on_mouse_entered():
	_mouse_in_panel = true
	if not timer.is_stopped():
		timer.timeout.emit()
	timer.stop()

func _on_mouse_exited():
	if option_chosen:
		return
	_mouse_in_panel = false
	timer.start()
	await timer.timeout
	if _mouse_in_panel:
		return
	
	handled.emit(CANCEL_STRING)
	queue_free()

func _on_popup_hide():
	queue_free()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		pass
