class_name Patient
extends Node

@export var patient_name: String = "Unknown"
@export var age: int = 0
@export var occupation: String = ""
@export_multiline var description: String = ""

@export var disease_name: String = ""
@export var symptoms: Array[String] = []
@export var correct_treatment: String = ""
@export var severity: int = 0

@export var stress: int = 0
@export var infection_level: int = 0

@export var family_name: String = ""
@export var importance_level: int = 0
@export var trusts_doctor: int = 50

@export_multiline var introduction_dialogue: String = ""
@export_multiline var examination_dialogue: String = ""
@export_multiline var death_dialogue: String = ""
@export_multiline var cured_dialogue: String = ""

enum HealthState {
	WAITING,
	STABLE,
	WEAK,
	CRITICAL,
	DEAD,
	RECOVERED,
	STABILIZED,
	WORSENED,
}

var current_health_state: HealthState = HealthState.WAITING
var was_treated: bool = false
var was_examined: bool = false
var is_waiting: bool = true
var sprite_path: String = ""

static func from_dict(data: Dictionary) -> Patient:
	var patient := Patient.new()

	patient.patient_name = str(data.get("name", data.get("patient_name", "Unknown")))
	patient.age = int(data.get("age", 0))
	patient.occupation = str(data.get("occupation", ""))
	patient.description = str(data.get("description", ""))

	patient.disease_name = str(data.get("disease_name", ""))
	patient.symptoms.assign(data.get("symptoms", []))
	patient.correct_treatment = str(data.get("correct_treatment", ""))
	patient.severity = int(data.get("severity", 0))
	patient.sprite_path = str(data.get("sprite", ""))

	patient.stress = int(data.get("stress", 0))
	patient.infection_level = int(data.get("infection_level", patient.severity))

	patient.family_name = str(data.get("family_name", ""))
	patient.importance_level = int(data.get("importance_level", 0))
	patient.trusts_doctor = int(data.get("trusts_doctor", 50))

	patient.introduction_dialogue = str(data.get("introduction_dialogue", ""))
	patient.examination_dialogue = str(data.get("examination_dialogue", ""))
	patient.death_dialogue = str(data.get("death_dialogue", ""))
	patient.cured_dialogue = str(data.get("cured_dialogue", ""))

	patient.current_health_state = patient._get_initial_health_state_from_severity(patient.severity)
	patient.is_waiting = true

	return patient


func _get_initial_health_state_from_severity(value: int) -> HealthState:
	if value >= 80:
		return HealthState.CRITICAL
	if value >= 45:
		return HealthState.WEAK
	return HealthState.STABLE


func examine() -> Array[String]:
	was_examined = true
	return symptoms


func apply_herbal_treatment(recipe_name: String, outcome: String) -> HealthState:
	was_treated = true
	is_waiting = false

	match outcome:
		"good":
			_apply_good_outcome()

		"neutral":
			_apply_neutral_outcome()

		"bad":
			_apply_bad_outcome()

		"deadly":
			_apply_deadly_outcome()

		_:
			_apply_bad_outcome()

	return current_health_state


func _apply_good_outcome() -> void:
	match current_health_state:
		HealthState.CRITICAL:
			current_health_state = HealthState.STABILIZED
		HealthState.WEAK:
			current_health_state = HealthState.RECOVERED
		HealthState.STABLE:
			current_health_state = HealthState.RECOVERED
		HealthState.WORSENED:
			current_health_state = HealthState.STABILIZED
		HealthState.STABILIZED:
			current_health_state = HealthState.RECOVERED
		HealthState.WAITING:
			current_health_state = HealthState.RECOVERED

	infection_level = max(0, infection_level - 20)
	stress = max(0, stress - 5)


func _apply_neutral_outcome() -> void:
	match current_health_state:
		HealthState.CRITICAL:
			current_health_state = HealthState.STABILIZED
		HealthState.WEAK:
			current_health_state = HealthState.STABILIZED
		HealthState.STABLE:
			current_health_state = HealthState.STABLE
		HealthState.WORSENED:
			current_health_state = HealthState.STABILIZED
		HealthState.WAITING:
			current_health_state = HealthState.STABLE

	infection_level = max(0, infection_level - 5)


func _apply_bad_outcome() -> void:
	match current_health_state:
		HealthState.STABLE:
			current_health_state = HealthState.WEAK
		HealthState.WEAK:
			current_health_state = HealthState.CRITICAL
		HealthState.CRITICAL:
			die()
			return
		HealthState.STABILIZED:
			current_health_state = HealthState.WORSENED
		HealthState.WORSENED:
			current_health_state = HealthState.CRITICAL
		HealthState.WAITING:
			current_health_state = HealthState.WEAK

	infection_level += 15
	stress += 10


func _apply_deadly_outcome() -> void:
	match current_health_state:
		HealthState.CRITICAL, HealthState.WORSENED:
			die()
		_:
			current_health_state = HealthState.CRITICAL

	infection_level += 30
	stress += 20


func progress_disease() -> void:
	if current_health_state in [HealthState.DEAD, HealthState.RECOVERED]:
		return

	match current_health_state:
		HealthState.STABLE:
			current_health_state = HealthState.WEAK
		HealthState.WEAK:
			current_health_state = HealthState.CRITICAL
		HealthState.CRITICAL:
			die()
		HealthState.STABILIZED:
			current_health_state = HealthState.WEAK
		HealthState.WORSENED:
			current_health_state = HealthState.CRITICAL
		HealthState.WAITING:
			current_health_state = HealthState.WEAK

	infection_level += 10
	stress += 5


func die() -> void:
	current_health_state = HealthState.DEAD


func get_health_state_text() -> String:
	match current_health_state:
		HealthState.WAITING:
			return "Aguardando atendimento"
		HealthState.STABLE:
			return "Estável"
		HealthState.WEAK:
			return "Debilitado"
		HealthState.CRITICAL:
			return "Crítico"
		HealthState.DEAD:
			return "Morto"
		HealthState.RECOVERED:
			return "Recuperado"
		HealthState.STABILIZED:
			return "Estabilizado"
		HealthState.WORSENED:
			return "Piorou"

	return "Estado desconhecido"


func get_patient_summary() -> Dictionary:
	return {
		"name": patient_name,
		"age": age,
		"occupation": occupation,
		"description": description,
		"disease": disease_name,
		"state": current_health_state,
		"state_text": get_health_state_text(),
		"symptoms": symptoms,
		"treated": was_treated,
		"examined": was_examined,
		"severity": severity,
	}
