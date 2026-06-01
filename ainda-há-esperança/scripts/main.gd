extends Node2D
@onready var day_label: Label = $CanvasLayer/DiaryPanel/LeftPage/DayLabel
@onready var time_label: Label = $CanvasLayer/DiaryPanel/LeftPage/TimeLabel
@onready var resources_label: Label = $CanvasLayer/DiaryPanel/LeftPage/ResourcesLabel
@onready var patient_label: Label = $CanvasLayer/DiaryPanel/LeftPage/PatientLabel
@onready var symptoms_label: Label = $CanvasLayer/DiaryPanel/LeftPage/SymptomsLabel
@onready var mixture_label: Label = $CanvasLayer/DiaryPanel/LeftPage/MixtureLabel

@onready var diary_button: Button = $CanvasLayer/DiaryPanel/RightPage/DiaryButton
@onready var add_artemisia_button: Button = $CanvasLayer/DiaryPanel/RightPage/MedicineButton
@onready var add_valeriana_button: Button = $CanvasLayer/DiaryPanel/RightPage/HerbsButton
@onready var add_salvia_button: Button = $CanvasLayer/DiaryPanel/RightPage/CreateMedicineButton
@onready var apply_mixture_button: Button = $CanvasLayer/DiaryPanel/RightPage/ApplyMixtureButton
@onready var clear_mixture_button: Button = $CanvasLayer/DiaryPanel/RightPage/ClearMixtureButton
@onready var refuse_button: Button = $CanvasLayer/DiaryPanel/RightPage/RefuseButton
@onready var collect_herbs_button: Button = $CanvasLayer/DiaryPanel/RightPage/CollectHerbsButton
@onready var rest_button: Button = $CanvasLayer/DiaryPanel/RightPage/RestButton
@onready var back_button: Button = $CanvasLayer/DiaryPanel/RightPage/BackButton
@onready var action_menu: CanvasLayer = $CanvasLayer
@onready var world_diary_button: TextureButton = $background/diaryButton

@onready var background_blocker = $CanvasLayer/BackgroundBlocker
@onready var background_blocker_right = $CanvasLayer/BackgroundBlockerRight
@onready var background_blocker_left = $CanvasLayer/BackgroundBlockerLeft

@onready var patient_display: Control = $Character
@onready var patient_sprite: TextureRect = $Character/CharacterSprite

@onready var page_1 = $CanvasLayer/DiaryPanel/pages/page_1
@onready var page_2 = $CanvasLayer/DiaryPanel/pages/page_2
@onready var page_3 = $CanvasLayer/DiaryPanel/pages/page_3
@onready var page_4 = $CanvasLayer/DiaryPanel/pages/page_4
@onready var page_5 = $CanvasLayer/DiaryPanel/pages/page_5
@onready var page_6 = $CanvasLayer/DiaryPanel/pages/page_6
@onready var page_7 = $CanvasLayer/DiaryPanel/pages/page_main
@onready var day_log_label: RichTextLabel = $CanvasLayer/DiaryPanel/LeftPage/Label








var current_mixture := {
	ResourceManager.ARTEMISIA: 0,
	ResourceManager.VALERIANA: 0,
	ResourceManager.SALVIA: 0,
}


func _ready() -> void:
	
	background_blocker.gui_input.connect(_on_background_clicked)
	background_blocker_left.gui_input.connect(_on_background_clicked)
	background_blocker_right.gui_input.connect(_on_background_clicked)
	
	action_menu.visible = false
	world_diary_button.pressed.connect(_on_world_diary_pressed)

	diary_button.pressed.connect(_on_diary_pressed)
	add_artemisia_button.pressed.connect(_on_add_artemisia_pressed)
	add_valeriana_button.pressed.connect(_on_add_valeriana_pressed)
	add_salvia_button.pressed.connect(_on_add_salvia_pressed)
	apply_mixture_button.pressed.connect(_on_apply_mixture_pressed)
	clear_mixture_button.pressed.connect(_on_clear_mixture_pressed)
	refuse_button.pressed.connect(_on_refuse_pressed)
	collect_herbs_button.pressed.connect(_on_collect_herbs_pressed)
	rest_button.pressed.connect(_on_rest_pressed)
	back_button.pressed.connect(_on_back_pressed)
	GameState.patient_changed.connect(_on_patient_changed)

	page_1.pressed.connect(func(): _show_day_log(1))
	page_2.pressed.connect(func(): _show_day_log(2))
	page_3.pressed.connect(func(): _show_day_log(3))
	page_4.pressed.connect(func(): _show_day_log(4))
	page_5.pressed.connect(func(): _show_day_log(5))
	page_6.pressed.connect(func(): _show_day_log(6))
	page_7.pressed.connect(func(): _show_day_log(7))


	_configure_button_texts()
	_connect_game_state_signals()
	_update_ui()


func _configure_button_texts() -> void:
	add_artemisia_button.text = "Adicionar artemísia"
	add_valeriana_button.text = "Adicionar valeriana"
	add_salvia_button.text = "Adicionar sálvia"
	apply_mixture_button.text = "Aplicar mistura"
	clear_mixture_button.text = "Limpar mistura"
	collect_herbs_button.text = "Coletar ervas"
	rest_button.text = "Descansar"

func _on_world_diary_pressed() -> void:
	action_menu.visible = true
	_update_ui()
	
func _on_patient_changed(_patient) -> void:
	_update_ui()

func _update_patient_sprite() -> void:
	var patient = GameState.current_patient

	if patient == null:
		patient_display.visible = false
		patient_sprite.texture = null
		return

	var sprite_path: String = str(patient.sprite_path)

	var texture := load(sprite_path)

	if texture == null:
		patient_display.visible = false
		patient_sprite.texture = null
		return

	patient_sprite.texture = texture
	patient_display.visible = true


func _on_background_clicked(event):
	if event is InputEventMouseButton and event.pressed:
		action_menu.visible = false

func _connect_game_state_signals() -> void:
	if not GameState.day_changed.is_connected(_update_ui):
		GameState.day_changed.connect(_update_ui)

	if not GameState.time_changed.is_connected(_update_ui):
		GameState.time_changed.connect(_update_ui)

	if not GameState.resources_changed.is_connected(_update_ui):
		GameState.resources_changed.connect(_update_ui)

	if not GameState.patient_changed.is_connected(_update_ui):
		GameState.patient_changed.connect(_update_ui)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if action_menu.visible:
			action_menu.visible = false
		else:
			_on_back_pressed()


func _update_ui(_value = null) -> void:
	day_label.text = "Dia %d de %d" % [
		GameState.current_day,
		GameState.time_manager.max_days,
	]

	time_label.text = "Horário: %02d:00" % GameState.current_hour

	resources_label.text = "Artemísia: %d | Valeriana: %d | Sálvia: %d" % [
		GameState.artemisia,
		GameState.valeriana,
		GameState.salvia,
	]

	_update_mixture_label()

	var patient: Patient = GameState.current_patient

	if patient == null:
		patient_label.text = "Nenhum paciente aguardando."
		symptoms_label.text = ""
		_set_patient_buttons_enabled(false)
		return

	patient_label.text = "Paciente: %s\n%s\nEstado: %s" % [
		patient.patient_name,
		patient.description,
		patient.get_health_state_text(),
	]

	symptoms_label.text = "Sintomas: %s" % ", ".join(patient.symptoms)

	_set_patient_buttons_enabled(not patient.was_treated)
	_update_patient_sprite()

func _update_mixture_label() -> void:
	mixture_label.text = "Mistura: %d Artemísia | %d Valeriana | %d Sálvia (%d/3)" % [
		current_mixture[ResourceManager.ARTEMISIA],
		current_mixture[ResourceManager.VALERIANA],
		current_mixture[ResourceManager.SALVIA],
		_get_current_mixture_total(),
	]


func _set_patient_buttons_enabled(enabled: bool) -> void:
	var mixture_total := _get_current_mixture_total()

	add_artemisia_button.disabled = not enabled or mixture_total >= 3
	add_valeriana_button.disabled = not enabled or mixture_total >= 3
	add_salvia_button.disabled = not enabled or mixture_total >= 3

	apply_mixture_button.disabled = not enabled or mixture_total != 3
	clear_mixture_button.disabled = mixture_total == 0

	refuse_button.disabled = not enabled


func _show_day_log(day: int) -> void:
	if day > GameState.current_day:
		return

	var entries := GameState.get_diary_entries_for_day(day)

	if entries.is_empty():
		return

	var text := "Dia %d\n\n" % day

	for entry in entries:
		text += "%s\n\n" % entry

	day_log_label.text = text


func _get_current_mixture_total() -> int:
	return int(current_mixture[ResourceManager.ARTEMISIA]) \
		+ int(current_mixture[ResourceManager.VALERIANA]) \
		+ int(current_mixture[ResourceManager.SALVIA])


func _add_herb_to_mixture(herb_name: String) -> void:
	if _get_current_mixture_total() >= 3:
		return

	current_mixture[herb_name] = int(current_mixture[herb_name]) + 1
	_update_ui()


func _clear_mixture() -> void:
	current_mixture[ResourceManager.ARTEMISIA] = 0
	current_mixture[ResourceManager.VALERIANA] = 0
	current_mixture[ResourceManager.SALVIA] = 0
	_update_ui()


func _on_diary_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/diary.tscn")


func _on_add_artemisia_pressed() -> void:
	_add_herb_to_mixture(ResourceManager.ARTEMISIA)


func _on_add_valeriana_pressed() -> void:
	_add_herb_to_mixture(ResourceManager.VALERIANA)


func _on_add_salvia_pressed() -> void:
	_add_herb_to_mixture(ResourceManager.SALVIA)


func _on_apply_mixture_pressed() -> void:
	if _get_current_mixture_total() != 3:
		return

	GameState.treat_current_patient_with_combination(current_mixture.duplicate(true))
	_clear_mixture()


func _on_clear_mixture_pressed() -> void:
	_clear_mixture()


func _on_refuse_pressed() -> void:
	GameState.refuse_current_patient()
	_clear_mixture()


func _on_collect_herbs_pressed() -> void:
	GameState.collect_herbs()


func _on_rest_pressed() -> void:
	GameState.rest()
	_clear_mixture()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
