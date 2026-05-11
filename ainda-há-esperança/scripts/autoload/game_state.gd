extends Node

signal day_changed(new_day: int)
signal time_changed(current_hour: int)
signal diary_updated
signal resources_changed
signal patient_changed(patient: Patient)

const MAX_DAYS := 7
const START_HOUR := 7
const NIGHT_HOUR := 21

const TREATMENT_EFFECTIVENESS := {
	ResourceManager.MEDICINE: 30,
	ResourceManager.HERBS: 15,
}

var current_day: int = 1
var current_hour: int = START_HOUR

# Variáveis espelho para manter compatibilidade com scripts antigos da UI.
# A fonte real dos dados é o ResourceManager.
var medicine: int = 0
var herbs: int = 0
var hope: int = 0
var food: int = 0
var money: int = 0

var current_patient: Patient = null
var diary_entries: Array[String] = []

var family := {
	"pai": {
		"name": "Senhor Silver",
		"health": 80,
		"state": "saudável"
	},
	"filho": {
		"name": "Bart",
		"health": 45,
		"state": "acamado"
	},
	"filha": {
		"name": "Lisa",
		"faith": 70,
		"trust": 40
	},
	"avo": {
		"name": "Vovô Silver",
		"health": 60,
		"state": "frágil"
	}
}

var patients_by_day := {
	1: [
		{
			"name": "Nara",
			"description": "Uma mulher cansada chega pedindo ervas para tratar o pai.",
			"symptoms": ["febre", "tosse", "fraqueza"],
			"severity": 35
		}
	],
	2: [
		{
			"name": "Seu Antônio",
			"description": "Um homem idoso chega tremendo, com manchas escuras nos braços.",
			"symptoms": ["calafrios", "manchas", "delírio"],
			"severity": 55
		}
	],
	3: [
		{
			"name": "Clara Mendes",
			"description": "Uma jovem procura ajuda depois de perder quase toda a família.",
			"symptoms": ["febre alta", "dor no peito", "fraqueza"],
			"severity": 70
		}
	],
	4: [
		{
			"name": "Tomás",
			"description": "Um pescador robusto, mas com os olhos fundos de quem não dorme há dias.",
			"symptoms": ["insônia", "tosse seca", "dor de cabeça"],
			"severity": 40
		}
	],
	5: [
		{
			"name": "Dona Perpétua",
			"description": "A padeira da vila. Chegou apoiada na porta, mal conseguindo ficar de pé.",
			"symptoms": ["fraqueza extrema", "vômito", "febre"],
			"severity": 65
		}
	],
	6: [
		{
			"name": "Menino desconhecido",
			"description": "Uma criança sem nome, trazida por um vizinho. Ninguém sabe de onde veio.",
			"symptoms": ["manchas roxas", "delírio", "febre alta"],
			"severity": 80
		}
	],
	7: [
		{
			"name": "Padre Alves",
			"description": "O último homem de fé da vila. Veio até você antes de ir embora para sempre.",
			"symptoms": ["tosse com sangue", "fraqueza", "dor no peito"],
			"severity": 75
		}
	]
}

var patient_manager: PatientManager
var resource_manager: ResourceManager


func _ready() -> void:
	_setup_managers()
	_sync_resource_cache()


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

	if not patient_manager.patient_changed.is_connected(_on_patient_changed):
		patient_manager.patient_changed.connect(_on_patient_changed)

	if not patient_manager.queue_empty.is_connected(_on_queue_empty):
		patient_manager.queue_empty.connect(_on_queue_empty)

	if not resource_manager.resources_changed.is_connected(_on_resources_changed):
		resource_manager.resources_changed.connect(_on_resources_changed)


func start_new_game() -> void:
	_setup_managers()
	current_day = 1
	current_hour = START_HOUR

	resource_manager.reset()
	patient_manager.reset()
	diary_entries.clear()
	_reset_family()
	_load_patients_for_current_day()
	_sync_resource_cache()

	day_changed.emit(current_day)
	time_changed.emit(current_hour)
	resources_changed.emit()

	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _reset_family() -> void:
	family["pai"]["health"] = 80
	family["pai"]["state"] = "saudável"
	family["filho"]["health"] = 45
	family["filho"]["state"] = "acamado"
	family["filha"]["faith"] = 70
	family["filha"]["trust"] = 40
	family["avo"]["health"] = 60
	family["avo"]["state"] = "frágil"


func _load_patients_for_current_day() -> void:
	var day_data: Array = patients_by_day.get(current_day, [])
	patient_manager.load_patients_for_day(day_data)


func _on_patient_changed(patient: Patient) -> void:
	current_patient = patient
	patient_changed.emit(patient)


func _on_queue_empty() -> void:
	add_diary_entry("Não há mais pacientes hoje. A vila guarda silêncio.")


func _on_resources_changed(_resources: Dictionary) -> void:
	_sync_resource_cache()
	resources_changed.emit()


func _sync_resource_cache() -> void:
	if resource_manager == null:
		return
	medicine = resource_manager.get_resource(ResourceManager.MEDICINE)
	herbs = resource_manager.get_resource(ResourceManager.HERBS)
	hope = resource_manager.get_resource(ResourceManager.HOPE)
	food = resource_manager.get_resource(ResourceManager.FOOD)
	money = resource_manager.get_resource(ResourceManager.MONEY)


func treat_current_patient(treatment_type: String) -> void:
	if patient_manager == null or not patient_manager.has_current_patient():
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
		Patient.HealthState.STABLE:
			add_diary_entry("%s foi estabilizado, ao menos por enquanto." % patient.patient_name)
		Patient.HealthState.WORSE:
			resource_manager.add_resource(ResourceManager.HOPE, -5)
			add_diary_entry("%s piorou apesar da tentativa de tratamento." % patient.patient_name)
		Patient.HealthState.CRITICAL:
			resource_manager.add_resource(ResourceManager.HOPE, -5)
			add_diary_entry("%s piorou apesar da tentativa de tratamento." % patient.patient_name)
		Patient.HealthState.DEAD:
			resource_manager.add_resource(ResourceManager.HOPE, -10)
			add_diary_entry("%s não resistiu." % patient.patient_name)


func advance_time(hours: int) -> void:
	current_hour += hours

	if current_hour >= NIGHT_HOUR:
		end_day()
	else:
		time_changed.emit(current_hour)


func end_day() -> void:
	patient_manager.progress_all_patients()
	current_day += 1

	if current_day > MAX_DAYS:
		end_game()
		return

	current_hour = START_HOUR
	_apply_night_consequences()
	_load_patients_for_current_day()

	day_changed.emit(current_day)
	time_changed.emit(current_hour)

	get_tree().change_scene_to_file("res://scenes/diary.tscn")


func _apply_night_consequences() -> void:
	if not resource_manager.consume_resource(ResourceManager.FOOD):
		resource_manager.set_resource(ResourceManager.FOOD, 0)
		resource_manager.add_resource(ResourceManager.HOPE, -10)
		family["filho"]["health"] -= 5
		add_diary_entry("A fome pesou sobre a casa durante a noite.")

	if family["filho"]["health"] <= 20:
		family["filho"]["state"] = "grave"
		add_diary_entry("Bart piorou. Sua respiração parece mais fraca.")

	if resource_manager.get_resource(ResourceManager.HOPE) <= 0:
		end_game()


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


func get_current_patient() -> Patient:
	return current_patient


func get_resource(resource_name: String) -> int:
	return resource_manager.get_resource(resource_name)


func get_resources() -> Dictionary:
	return resource_manager.get_snapshot()


func get_hope() -> int:
	return resource_manager.get_resource(ResourceManager.HOPE)


func get_food() -> int:
	return resource_manager.get_resource(ResourceManager.FOOD)


func get_herbs() -> int:
	return resource_manager.get_resource(ResourceManager.HERBS)


func get_medicine() -> int:
	return resource_manager.get_resource(ResourceManager.MEDICINE)


func get_money() -> int:
	return resource_manager.get_resource(ResourceManager.MONEY)


func add_diary_entry(text: String) -> void:
	diary_entries.append(text)
	diary_updated.emit()


func end_game() -> void:
	add_diary_entry("A história chegou ao fim.")
	get_tree().change_scene_to_file("res://scenes/end_game.tscn")
