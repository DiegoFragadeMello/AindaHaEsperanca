class_name Patient
extends Node

# Identificação
@export var patient_name: String = "Unknown"
@export var age: int = 0
@export var occupation: String = ""
@export_multiline var description: String = ""

# Doença
@export var disease_name: String = ""
@export var symptoms: Array[String] = []
@export var correct_treatment: String = ""
@export var severity: int = 50

# Estado do paciente
enum HealthState {
	STABLE,
	WORSE,
	CRITICAL,
	DEAD,
	RECOVERED
}

var current_health_state: HealthState = HealthState.STABLE

@export var health: int = 100
@export var stress: int = 0
@export var infection_level: int = 0

# Relacionamentos
@export var family_name: String = ""
@export var importance_level: int = 0
var trusts_doctor: int = 50

# Narrativa
@export_multiline var introduction_dialogue: String = ""
@export_multiline var examination_dialogue: String = ""
@export_multiline var death_dialogue: String = ""
@export_multiline var cured_dialogue: String = ""

# Controle
var was_treated: bool = false
var was_examined: bool = false
var is_waiting: bool = true


static func from_dict(data: Dictionary) -> Patient:
	var patient := Patient.new()
	patient.patient_name = str(data.get("name", data.get("patient_name", "Unknown")))
	patient.age = int(data.get("age", 0))
	patient.occupation = str(data.get("occupation", ""))
	patient.description = str(data.get("description", ""))
	patient.disease_name = str(data.get("disease_name", data.get("disease", "")))
	patient.correct_treatment = str(data.get("correct_treatment", ""))
	patient.severity = clampi(int(data.get("severity", 50)), 0, 100)
	patient.health = clampi(int(data.get("health", 100 - patient.severity)), 1, 100)
	patient.infection_level = patient.severity

	var raw_symptoms: Array = data.get("symptoms", [])
	patient.symptoms.clear()
	for symptom in raw_symptoms:
		patient.symptoms.append(str(symptom))

	patient.update_health_state()
	return patient


func _ready() -> void:
	update_health_state()


func examine() -> Array[String]:
	was_examined = true
	return symptoms


func apply_treatment(treatment_name: String, effectiveness: int = 0) -> HealthState:
	was_treated = true

	# Se houver tratamento correto definido, ele tem prioridade.
	# Se não houver, usa a efetividade recebida pelo GameState.
	if correct_treatment != "" and treatment_name == correct_treatment:
		heal()
		return current_health_state

	var final_effectiveness := effectiveness
	if correct_treatment != "" and treatment_name != correct_treatment:
		final_effectiveness = -20

	if final_effectiveness >= severity:
		heal()
	elif final_effectiveness >= int(severity * 0.45):
		stabilize(final_effectiveness)
	else:
		worsen()

	return current_health_state


func heal() -> void:
	current_health_state = HealthState.RECOVERED
	health = 100
	infection_level = 0


func stabilize(effectiveness: int = 0) -> void:
	health = clampi(health + max(5, effectiveness), 1, 100)
	infection_level = max(0, infection_level - max(5, effectiveness))
	update_health_state()

	if current_health_state != HealthState.RECOVERED and current_health_state != HealthState.DEAD:
		current_health_state = HealthState.STABLE


func worsen() -> void:
	infection_level += 25
	health -= 30
	stress += 10
	update_health_state()


func progress_disease() -> void:
	if current_health_state == HealthState.DEAD or current_health_state == HealthState.RECOVERED:
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
	else:
		current_health_state = HealthState.STABLE


func die() -> void:
	current_health_state = HealthState.DEAD
	health = 0


func get_patient_summary() -> Dictionary:
	return {
		"name": patient_name,
		"age": age,
		"disease": disease_name,
		"health": health,
		"state": current_health_state,
		"symptoms": symptoms,
		"treated": was_treated,
		"severity": severity,
	}
