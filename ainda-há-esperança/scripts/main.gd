extends Node2D

@onready var day_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/DayLabel
@onready var time_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/TimeLabel
@onready var resources_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/ResourcesLabel
@onready var patient_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/PatientLabel
@onready var symptoms_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/SymptomsLabel

@onready var diary_button: Button = $CanvasLayer/MarginContainer/VBoxContainer/DiaryButton
@onready var medicine_button: Button = $CanvasLayer/MarginContainer/VBoxContainer/MedicineButton
@onready var herbs_button: Button = $CanvasLayer/MarginContainer/VBoxContainer/HerbsButton
@onready var create_medicine_button: Button = $CanvasLayer/MarginContainer/VBoxContainer/CreateMedicineButton
@onready var refuse_button: Button = $CanvasLayer/MarginContainer/VBoxContainer/RefuseButton
@onready var rest_button: Button = $CanvasLayer/MarginContainer/VBoxContainer/RestButton
@onready var back_button: Button = $CanvasLayer/MarginContainer/VBoxContainer/BackButton


func _ready() -> void:
	_connect_button_signals()
	_connect_game_state_signals()
	_update_ui()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()


func _connect_button_signals() -> void:
	if not diary_button.pressed.is_connected(_on_diary_pressed):
		diary_button.pressed.connect(_on_diary_pressed)
	if not medicine_button.pressed.is_connected(_on_medicine_pressed):
		medicine_button.pressed.connect(_on_medicine_pressed)
	if not herbs_button.pressed.is_connected(_on_herbs_pressed):
		herbs_button.pressed.connect(_on_herbs_pressed)
	if not create_medicine_button.pressed.is_connected(_on_create_medicine_pressed):
		create_medicine_button.pressed.connect(_on_create_medicine_pressed)
	if not refuse_button.pressed.is_connected(_on_refuse_pressed):
		refuse_button.pressed.connect(_on_refuse_pressed)
	if not rest_button.pressed.is_connected(_on_rest_pressed):
		rest_button.pressed.connect(_on_rest_pressed)
	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)


func _connect_game_state_signals() -> void:
	if not GameState.day_changed.is_connected(_update_ui):
		GameState.day_changed.connect(_update_ui)
	if not GameState.time_changed.is_connected(_update_ui):
		GameState.time_changed.connect(_update_ui)
	if not GameState.resources_changed.is_connected(_update_ui):
		GameState.resources_changed.connect(_update_ui)
	if not GameState.patient_changed.is_connected(_update_ui):
		GameState.patient_changed.connect(_update_ui)


func _update_ui(_value = null) -> void:
	day_label.text = "Dia %d" % GameState.current_day
	time_label.text = "Horário: %02d:00" % GameState.current_hour

	var resources := GameState.get_resources()
	resources_label.text = "Ervas: %d | Remédios: %d | Comida: %d | Esperança: %d" % [
		int(resources.get(ResourceManager.HERBS, 0)),
		int(resources.get(ResourceManager.MEDICINE, 0)),
		int(resources.get(ResourceManager.FOOD, 0)),
		int(resources.get(ResourceManager.HOPE, 0))
	]

	var patient: Patient = GameState.get_current_patient()
	if patient == null:
		patient_label.text = "Nenhum paciente aguardando."
		symptoms_label.text = ""
		_set_patient_buttons_enabled(false)
		return

	patient_label.text = "Paciente: %s\n%s" % [
		patient.patient_name,
		patient.description
	]

	symptoms_label.text = "Sintomas: %s" % ", ".join(patient.symptoms)
	_set_patient_buttons_enabled(not patient.was_treated)


func _set_patient_buttons_enabled(enabled: bool) -> void:
	medicine_button.disabled = not enabled
	herbs_button.disabled = not enabled
	refuse_button.disabled = not enabled


func _on_diary_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/diary.tscn")


func _on_medicine_pressed() -> void:
	GameState.treat_current_patient(ResourceManager.MEDICINE)


func _on_herbs_pressed() -> void:
	GameState.treat_current_patient(ResourceManager.HERBS)


func _on_create_medicine_pressed() -> void:
	GameState.create_medicine()


func _on_refuse_pressed() -> void:
	GameState.treat_current_patient("refuse")


func _on_rest_pressed() -> void:
	GameState.rest()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
