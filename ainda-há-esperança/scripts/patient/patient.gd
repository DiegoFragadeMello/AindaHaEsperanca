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

@export var health: int = 100
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
	WORSE,
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
	patient.health = int(data.get("health", clamp(100 - patient.severity, 20, 100)))
	patient.stress = int(data.get("stress", 0))
	patient.infection_level = int(data.get("infection_level", patient.severity))
	patient.family_name = str(data.get("family_name", ""))
	patient.importance_level = int(data.get("importance_level", 0))
	patient.trusts_doctor = int(data.get("trusts_doctor", 50))
	patient.introduction_dialogue = str(data.get("introduction_dialogue", ""))
	patient.examination_dialogue = str(data.get("examination_dialogue", ""))
	patient.death_dialogue = str(data.get("death_dialogue", ""))
	patient.cured_dialogue = str(data.get("cured_dialogue", ""))
	patient.current_health_state = HealthState.WAITING
	patient.update_health_state()
	patient.is_waiting = true
	return patient


func examine() -> Array[String]:
	was_examined = true
	return symptoms


func apply_treatment(treatment_name: String, effectiveness: int = 0) -> HealthState:
	was_treated = true
	is_waiting = false

	var treatment_matches := correct_treatment == "" or treatment_name == correct_treatment
	var final_effectiveness := effectiveness

	if treatment_matches:
		final_effectiveness += 10
	else:
		final_effectiveness -= 15

	if final_effectiveness >= severity:
		heal()
		return current_health_state

	if final_effectiveness >= int(severity * 0.5):
		stabilize(final_effectiveness)
		return current_health_state

	worsen()
	return current_health_state


func heal() -> void:
	current_health_state = HealthState.RECOVERED
	health = 100
	infection_level = 0


func stabilize(effectiveness: int = 0) -> void:
	current_health_state = HealthState.STABILIZED
	health = clamp(health + max(5, effectiveness / 2), 1, 100)
	infection_level = max(0, infection_level - effectiveness)


func worsen() -> void:
	infection_level += 25
	health -= 30
	stress += 10
	update_health_state()
	if current_health_state != HealthState.DEAD:
		current_health_state = HealthState.WORSENED


func progress_disease() -> void:
	if current_health_state in [HealthState.DEAD, HealthState.RECOVERED]:
		return

	infection_level += 10
	health -= 15
	update_health_state()


func update_health_state() -> void:
	if health <= 0:
		die()
	elif health <= 25:
		current_health_state = HealthState.CRITICAL
	elif health <= 60:
		current_health_state = HealthState.WORSE
	elif current_health_state != HealthState.WAITING:
		current_health_state = HealthState.STABLE


func die() -> void:
	current_health_state = HealthState.DEAD
	health = 0


func get_patient_summary() -> Dictionary:
	return {
		"name": patient_name,
		"age": age,
		"occupation": occupation,
		"description": description,
		"disease": disease_name,
		"health": health,
		"state": current_health_state,
		"symptoms": symptoms,
		"treated": was_treated,
		"examined": was_examined,
		"severity": severity,
	}
