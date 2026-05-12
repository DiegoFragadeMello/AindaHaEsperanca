extends Node

signal day_changed(new_day: int)
signal time_changed(current_hour: int)
signal diary_updated
signal resources_changed
signal family_changed
signal patient_changed(patient: Patient)

const PATIENTS_JSON_PATH := "res://data/characters/patients.json"
const FAMILY_JSON_PATH := "res://data/characters/family.json"

const TREATMENT_EFFECTIVENESS := {
	ResourceManager.MEDICINE: 30,
	ResourceManager.HERBS: 15,
}

var diary_entries: Array[String] = []

var patient_manager: PatientManager
var resource_manager: ResourceManager
var time_manager: TimeManager
var family_manager: FamilyManager

# Variáveis espelho para manter compatibilidade com UIs/scripts existentes.
var current_day: int = 1
var current_hour: int = 7
var medicine: int = 0
var herbs: int = 0
var hope: int = 0
var food: int = 0
var money: int = 0
var current_patient: Patient = null
var family: Dictionary = {}


func _ready() -> void:
	_setup_managers()
	_sync_time_mirror()
	_sync_resources_mirror()
	_sync_family_mirror()


func _setup_managers() -> void:
	patient_manager = get_node_or_null("PatientManager") as PatientManager
	if patient_manager == null:
		patient_manager = PatientManager.new()
		patient_manager.name = "PatientManager"
		add_child(patient_manager)

	resource_manager = get_node_or_null("ResourceManager") as ResourceManager
	if resource_manager == null:
		resource_manager = ResourceManager.new()
		resource_manager.name = "ResourceManager"
		add_child(resource_manager)

	time_manager = get_node_or_null("TimeManager") as TimeManager
	if time_manager == null:
		time_manager = TimeManager.new()
		time_manager.name = "TimeManager"
		add_child(time_manager)

	family_manager = get_node_or_null("FamilyManager") as FamilyManager
	if family_manager == null:
		family_manager = FamilyManager.new()
		family_manager.name = "FamilyManager"
		add_child(family_manager)

	if not patient_manager.patient_changed.is_connected(_on_patient_changed):
		patient_manager.patient_changed.connect(_on_patient_changed)
	if not patient_manager.queue_empty.is_connected(_on_queue_empty):
		patient_manager.queue_empty.connect(_on_queue_empty)
	if not resource_manager.resources_changed.is_connected(_on_resources_changed):
		resource_manager.resources_changed.connect(_on_resources_changed)
	if not time_manager.day_changed.is_connected(_on_day_changed):
		time_manager.day_changed.connect(_on_day_changed)
	if not time_manager.time_changed.is_connected(_on_time_changed):
		time_manager.time_changed.connect(_on_time_changed)
	if not time_manager.night_started.is_connected(_on_night_started):
		time_manager.night_started.connect(_on_night_started)
	if not time_manager.game_days_finished.is_connected(_on_game_days_finished):
		time_manager.game_days_finished.connect(_on_game_days_finished)
	if not family_manager.family_changed.is_connected(_on_family_changed):
		family_manager.family_changed.connect(_on_family_changed)


func start_new_game() -> void:
	_setup_managers()
	time_manager.reset()
	resource_manager.reset()
	patient_manager.reset()
	family_manager.load_from_json(FAMILY_JSON_PATH)
	diary_entries.clear()
	_sync_time_mirror()
	_sync_resources_mirror()
	_sync_family_mirror()
	_load_patients_for_current_day()
	resources_changed.emit()
	family_changed.emit()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _load_patients_for_current_day() -> void:
	patient_manager.load_patients_from_json(current_day, PATIENTS_JSON_PATH)


func _on_patient_changed(patient: Patient) -> void:
	current_patient = patient
	patient_changed.emit(patient)


func _on_queue_empty() -> void:
	add_diary_entry("Não há mais pacientes hoje. A vila guarda silêncio.")


func _on_resources_changed(_resources: Dictionary) -> void:
	_sync_resources_mirror()
	resources_changed.emit()


func _on_family_changed(_members: Dictionary) -> void:
	_sync_family_mirror()
	family_changed.emit()


func _on_day_changed(new_day: int) -> void:
	current_day = new_day
	day_changed.emit(new_day)


func _on_time_changed(new_hour: int) -> void:
	current_hour = new_hour
	time_changed.emit(new_hour)


func _on_night_started(_day_finished: int) -> void:
	end_day()


func _on_game_days_finished() -> void:
	end_game()


func _sync_time_mirror() -> void:
	if time_manager == null:
		return
	current_day = time_manager.current_day
	current_hour = time_manager.current_hour


func _sync_resources_mirror() -> void:
	if resource_manager == null:
		return
	medicine = resource_manager.medicine
	herbs = resource_manager.herbs
	hope = resource_manager.hope
	food = resource_manager.food
	money = resource_manager.money


func _sync_family_mirror() -> void:
	if family_manager == null:
		return
	family = family_manager.get_snapshot()


func treat_current_patient(treatment_type: String) -> void:
	if not patient_manager.has_current_patient():
		return

	var patient: Patient = patient_manager.current_patient

	match treatment_type:
		ResourceManager.MEDICINE:
			if not resource_manager.consume_resource(ResourceManager.MEDICINE):
				add_diary_entry("Tentei usar remédio, mas não havia nenhum disponível.")
				return
			_resolve_and_log(patient, treatment_type, TREATMENT_EFFECTIVENESS[ResourceManager.MEDICINE])
			advance_time(3)

		ResourceManager.HERBS:
			if not resource_manager.consume_resource(ResourceManager.HERBS):
				add_diary_entry("Tentei usar ervas, mas o estoque estava vazio.")
				return
			_resolve_and_log(patient, treatment_type, TREATMENT_EFFECTIVENESS[ResourceManager.HERBS])
			advance_time(3)

		"refuse":
			resource_manager.add_resource(ResourceManager.HOPE, -5)
			patient_manager.refuse_current_patient()
			add_diary_entry("Recusei atendimento a %s." % patient.patient_name)
			advance_time(1)

		_:
			push_warning("Tipo de tratamento desconhecido: %s" % treatment_type)


func _resolve_and_log(patient: Patient, treatment_name: String, effectiveness: int) -> void:
	var result: Patient.HealthState = patient_manager.treat_current_patient(treatment_name, effectiveness)

	match result:
		Patient.HealthState.RECOVERED:
			resource_manager.add_resource(ResourceManager.HOPE, 5)
			add_diary_entry("%s se recuperou após o tratamento." % patient.patient_name)
		Patient.HealthState.STABILIZED, Patient.HealthState.STABLE:
			add_diary_entry("%s foi estabilizado, ao menos por enquanto." % patient.patient_name)
		Patient.HealthState.WORSENED, Patient.HealthState.WORSE, Patient.HealthState.CRITICAL:
			resource_manager.add_resource(ResourceManager.HOPE, -5)
			add_diary_entry("%s piorou apesar da tentativa de tratamento." % patient.patient_name)
		Patient.HealthState.DEAD:
			resource_manager.add_resource(ResourceManager.HOPE, -10)
			add_diary_entry("%s não resistiu." % patient.patient_name)


func advance_time(hours: int) -> void:
	time_manager.advance_time(hours)
	_sync_time_mirror()


func end_day() -> void:
	patient_manager.progress_all_patients()
	_apply_night_consequences()

	if resource_manager.get_resource(ResourceManager.HOPE) <= 0:
		end_game()
		return

	if not time_manager.start_next_day():
		return

	_sync_time_mirror()
	_load_patients_for_current_day()
	get_tree().change_scene_to_file("res://scenes/diary.tscn")


func _apply_night_consequences() -> void:
	if not resource_manager.consume_resource(ResourceManager.FOOD):
		resource_manager.set_resource(ResourceManager.FOOD, 0)
		resource_manager.add_resource(ResourceManager.HOPE, -5)
		family_manager.change_health("filho", -5)
		add_diary_entry("A fome pesou sobre a casa durante a noite.")

	var filho := family_manager.get_member("filho")
	if int(filho.get("health", 100)) <= 20:
		family_manager.set_member_value("filho", "state", "grave")
		add_diary_entry("Bart piorou. Sua respiração parece mais fraca.")


func create_medicine() -> void:
	if not resource_manager.consume_resource(ResourceManager.HERBS, 2):
		add_diary_entry("Tentei sintetizar remédio, mas faltavam ervas.")
		return

	resource_manager.add_resource(ResourceManager.MEDICINE, 1)
	add_diary_entry("Usei ervas amargas para preparar um novo medicamento.")
	advance_time(2)


func rest() -> void:
	resource_manager.add_resource(ResourceManager.HOPE, 2)
	add_diary_entry("Tentei repousar, mas a culpa não me deixou dormir em paz.")
	advance_time(2)


func get_resource(resource_name: String) -> int:
	return resource_manager.get_resource(resource_name)


func get_resources() -> Dictionary:
	return resource_manager.get_snapshot()


func get_family() -> Dictionary:
	return family_manager.get_snapshot()


func get_family_member(member_id: String) -> Dictionary:
	return family_manager.get_member(member_id)


func get_hope() -> int:
	return resource_manager.hope


func get_food() -> int:
	return resource_manager.food


func get_herbs() -> int:
	return resource_manager.herbs


func get_medicine() -> int:
	return resource_manager.medicine


func get_money() -> int:
	return resource_manager.money


func add_diary_entry(text: String) -> void:
	diary_entries.append(text)
	diary_updated.emit()


func get_save_data() -> Dictionary:
	return {
		"time": time_manager.get_snapshot(),
		"resources": resource_manager.get_snapshot(),
		"diary_entries": diary_entries,
		"family": family_manager.get_snapshot(),
	}


func load_save_data(data: Dictionary) -> void:
	_setup_managers()
	time_manager.load_snapshot(data.get("time", {}))
	resource_manager.load_snapshot(data.get("resources", {}))
	diary_entries.assign(data.get("diary_entries", []))
	family_manager.load_snapshot(data.get("family", {}))
	_sync_time_mirror()
	_sync_resources_mirror()
	_sync_family_mirror()
	_load_patients_for_current_day()
	diary_updated.emit()
	family_changed.emit()


func end_game() -> void:
	add_diary_entry("A história chegou ao fim.")
	get_tree().change_scene_to_file("res://scenes/end_game.tscn")
