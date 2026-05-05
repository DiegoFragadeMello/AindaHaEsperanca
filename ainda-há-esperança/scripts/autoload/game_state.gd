extends Node

signal day_changed(new_day: int)
signal time_changed(current_hour: int)
signal diary_updated
signal resources_changed
signal patient_changed

const MAX_DAYS := 10
const START_HOUR := 7
const NIGHT_HOUR := 21

var current_day: int = 1
var current_hour: int = START_HOUR

var hope: int = 50
var food: int = 3
var herbs: int = 5
var medicine: int = 2

var current_patient: Dictionary = {}

var diary_entries: Array[String] = []

var family := {
	"bart": {
		"name": "Bart",
		"health": 45,
		"state": "acamado"
	},
	"lisa": {
		"name": "Lisa",
		"faith": 70,
		"trust": 40
	}
}

var patients_by_day := {
	1: [
		{
			"name": "Nara",
			"description": "Uma mulher cansada chega pedindo ervas para tratar o pai.",
			"symptoms": ["febre", "tosse", "fraqueza"],
			"severity": 35,
			"treated": false,
			"result": ""
		}
	],
	2: [
		{
			"name": "Seu Antônio",
			"description": "Um homem idoso chega tremendo, com manchas escuras nos braços.",
			"symptoms": ["calafrios", "manchas", "delírio"],
			"severity": 55,
			"treated": false,
			"result": ""
		}
	],
	3: [
		{
			"name": "Clara Mendes",
			"description": "Uma jovem procura ajuda depois de perder quase toda a família.",
			"symptoms": ["febre alta", "dor no peito", "fraqueza"],
			"severity": 70,
			"treated": false,
			"result": ""
		}
	]
}


func start_new_game() -> void:
	current_day = 1
	current_hour = START_HOUR

	hope = 50
	food = 3
	herbs = 5
	medicine = 2

	diary_entries.clear()
	current_patient.clear()

	family.bart.health = 45
	family.bart.state = "acamado"
	family.lisa.faith = 70
	family.lisa.trust = 40

	add_diary_entry("12 de junho de 1865.\nAinda há esperança. Tem de haver.")
	load_first_patient_of_day()

	get_tree().change_scene_to_file("res://scenes/main.tscn")


func load_first_patient_of_day() -> void:
	var patients: Array = patients_by_day.get(current_day, [])

	if patients.is_empty():
		current_patient = {}
	else:
		current_patient = patients[0]

	patient_changed.emit()


func advance_time(hours: int) -> void:
	current_hour += hours

	if current_hour >= NIGHT_HOUR:
		end_day()
	else:
		time_changed.emit(current_hour)


func end_day() -> void:
	add_diary_entry("O dia %d chegou ao fim. A noite trouxe silêncio, medo e incerteza." % current_day)

	current_day += 1

	if current_day > MAX_DAYS:
		end_game()
		return

	current_hour = START_HOUR
	apply_night_consequences()
	load_first_patient_of_day()

	day_changed.emit(current_day)
	time_changed.emit(current_hour)

	get_tree().change_scene_to_file("res://scenes/diary.tscn")


func apply_night_consequences() -> void:
	food -= 1

	if food < 0:
		food = 0
		hope -= 5
		family.bart.health -= 5
		add_diary_entry("A fome pesou sobre a casa durante a noite.")

	if family.bart.health <= 20:
		family.bart.state = "grave"
		add_diary_entry("Bart piorou. Sua respiração parece mais fraca.")


func treat_current_patient(treatment_type: String) -> void:
	if current_patient.is_empty():
		return

	match treatment_type:
		"medicine":
			if medicine <= 0:
				add_diary_entry("Tentei aplicar um medicamento, mas não havia nenhum disponível.")
				return

			medicine -= 1
			_resolve_treatment(25, "medicamento")

		"herbs":
			if herbs <= 0:
				add_diary_entry("Tentei preparar ervas, mas os potes estavam vazios.")
				return

			herbs -= 1
			_resolve_treatment(15, "ervas")

		"refuse":
			hope -= 5
			current_patient.result = "recusado"
			current_patient.treated = true

			add_diary_entry("Recusei atendimento a %s. Talvez eu nunca esqueça seu olhar." % current_patient.name)

	resources_changed.emit()
	patient_changed.emit()


func _resolve_treatment(effectiveness: int, treatment_name: String) -> void:
	var severity: int = current_patient.severity
	var result_score := effectiveness + randi_range(0, 30)

	current_patient.treated = true

	if result_score >= severity:
		current_patient.result = "melhora"
		hope += 5
		add_diary_entry("%s recebeu tratamento com %s e apresentou melhora." % [
			current_patient.name,
			treatment_name
		])
	elif result_score >= severity / 2:
		current_patient.result = "estabilizado"
		add_diary_entry("%s recebeu tratamento com %s. Não melhorou, mas resistiu por enquanto." % [
			current_patient.name,
			treatment_name
		])
	else:
		current_patient.result = "agravamento"
		hope -= 5
		add_diary_entry("%s recebeu tratamento com %s, mas seu estado piorou." % [
			current_patient.name,
			treatment_name
		])

	advance_time(3)


func create_medicine() -> void:
	if herbs < 2:
		add_diary_entry("Tentei sintetizar remédio, mas faltavam ervas.")
		return

	herbs -= 2
	medicine += 1

	add_diary_entry("Usei ervas amargas para preparar um novo medicamento.")
	advance_time(2)

	resources_changed.emit()


func rest() -> void:
	add_diary_entry("Tentei repousar, mas a culpa não me deixou dormir em paz.")
	hope += 2
	advance_time(2)


func add_diary_entry(text: String) -> void:
	diary_entries.append(text)
	diary_updated.emit()


func end_game() -> void:
	add_diary_entry("A história chegou ao fim.")

	if hope <= 0:
		print("Final: sem esperança.")
	elif family.bart.health <= 0:
		print("Final: perda familiar.")
	else:
		print("Final: ainda há esperança.")

	get_tree().change_scene_to_file("res://scenes/menu.tscn")