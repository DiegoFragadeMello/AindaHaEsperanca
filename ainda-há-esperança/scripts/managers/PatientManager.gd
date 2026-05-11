class_name PatientManager
extends Node

signal patient_changed(patient: Patient)
signal queue_empty

const DEFAULT_PATIENTS_PATH := "res://data/characters/patients.json"

var current_patient: Patient = null
var patient_queue: Array[Patient] = []
var treated_patients: Array[Patient] = []
var dead_patients: Array[Patient] = []


func reset() -> void:
	current_patient = null
	patient_queue.clear()
	treated_patients.clear()
	dead_patients.clear()
	patient_changed.emit(null)


func load_patients_from_json(day: int, path: String = DEFAULT_PATIENTS_PATH) -> void:
	var data := JsonDataLoader.load_json(path)
	var days: Dictionary = data.get("days", {})
	var day_data: Array = days.get(str(day), [])
	load_patients_for_day(day_data)


func load_patients_for_day(day_data: Array) -> void:
	patient_queue.clear()
	current_patient = null

	for data in day_data:
		if typeof(data) != TYPE_DICTIONARY:
			push_warning("Paciente ignorado: entrada inválida no JSON.")
			continue

		var patient: Patient = Patient.from_dict(data)
		patient_queue.append(patient)

	call_next_patient()


func call_next_patient() -> Patient:
	if patient_queue.is_empty():
		current_patient = null
		queue_empty.emit()
		patient_changed.emit(null)
		return null

	current_patient = patient_queue.pop_front()
	current_patient.is_waiting = false
	patient_changed.emit(current_patient)
	return current_patient


func treat_current_patient(treatment_name: String, effectiveness: int) -> Patient.HealthState:
	if current_patient == null:
		return Patient.HealthState.WAITING

	var treated_patient := current_patient
	var result: Patient.HealthState = treated_patient.apply_treatment(treatment_name, effectiveness)

	match result:
		Patient.HealthState.RECOVERED, Patient.HealthState.STABILIZED, Patient.HealthState.WORSENED, Patient.HealthState.STABLE, Patient.HealthState.WORSE, Patient.HealthState.CRITICAL:
			treated_patients.append(treated_patient)
		Patient.HealthState.DEAD:
			dead_patients.append(treated_patient)

	current_patient = null
	call_next_patient()
	return result


func refuse_current_patient() -> void:
	if current_patient == null:
		return

	current_patient.current_health_state = Patient.HealthState.WORSENED
	current_patient.was_treated = false
	treated_patients.append(current_patient)
	current_patient = null
	call_next_patient()


func progress_all_patients() -> void:
	for patient in patient_queue:
		patient.progress_disease()
		if patient.current_health_state == Patient.HealthState.DEAD and not dead_patients.has(patient):
			dead_patients.append(patient)

	if current_patient != null:
		current_patient.progress_disease()
		if current_patient.current_health_state == Patient.HealthState.DEAD and not dead_patients.has(current_patient):
			dead_patients.append(current_patient)


func get_queue_count() -> int:
	return patient_queue.size()


func get_treated_count() -> int:
	return treated_patients.size()


func get_dead_count() -> int:
	return dead_patients.size()


func has_current_patient() -> bool:
	return current_patient != null
