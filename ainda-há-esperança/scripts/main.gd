extends Node2D

@onready var day_label: Label = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/DayLabel
@onready var time_label: Label = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/TimeLabel
@onready var resources_label: Label = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/ResourcesLabel
@onready var patient_label: Label = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/PatientLabel
@onready var symptoms_label: Label = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/SymptomsLabel
@onready var mixture_label: Label = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/MixtureLabel

@onready var diary_button: Button = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/DiaryButton
@onready var add_artemisia_button: Button = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/MedicineButton
@onready var add_valeriana_button: Button = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/HerbsButton
@onready var add_salvia_button: Button = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/CreateMedicineButton
@onready var apply_mixture_button: Button = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/ApplyMixtureButton
@onready var clear_mixture_button: Button = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/ClearMixtureButton
@onready var refuse_button: Button = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/RefuseButton
@onready var collect_herbs_button: Button = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/CollectHerbsButton
@onready var rest_button: Button = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/RestButton
@onready var back_button: Button = $CanvasLayer/MarginContainer/ScrollContainer/VBoxContainer/BackButton

var current_mixture := {
	ResourceManager.ARTEMISIA: 0,
	ResourceManager.VALERIANA: 0,
	ResourceManager.SALVIA: 0,
}


func _ready() -> void:
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