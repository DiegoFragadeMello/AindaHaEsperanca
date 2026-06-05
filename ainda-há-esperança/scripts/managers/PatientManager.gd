class_name PatientManager
extends Node

signal patient_changed(patient: Patient)
signal queue_empty

const DEFAULT_PATIENTS_PATH := "res://data/characters/patients.json"

var current_patient: Patient = null
var patient_queue: Array[Patient] = []
var treated_patients: Array[Patient] = []
var refused_patients: Array[Patient] = []
var dead_patients: Array[Patient] = []
var all_patients_seen: Array[Patient] = []

var total_campaign_patients: int = 0


func reset() -> void:
	current_patient = null
	patient_queue.clear()
	treated_patients.clear()
	refused_patients.clear()
	dead_patients.clear()
	all_patients_seen.clear()
	total_campaign_patients = 0
	patient_changed.emit(null)


func load_total_campaign_patients(path: String = DEFAULT_PATIENTS_PATH) -> void:
	var data := JsonDataLoader.load_json(path)
	var days: Dictionary = data.get("days", {})

	total_campaign_patients = 0

	for day_key in days.keys():
		var day_patients: Array = days.get(day_key, [])
		total_campaign_patients += day_patients.size()


func load_patients_from_json(day: int, path: String = DEFAULT_PATIENTS_PATH) -> void:
	var data := JsonDataLoader.load_json(path)
	var days: Dictionary = data.get("days", {})
	var day_data: Array = days.get(str(day), [])

	load_patients_for_day(day_data)


func load_patients_for_day(day_data: Array) -> void:
	patient_queue.clear()
	current_patient = null

	for raw_patient_data in day_data:
		if typeof(raw_patient_data) != TYPE_DICTIONARY:
			push_warning("Paciente ignorado: entrada inválida no JSON.")
			continue

		var patient: Patient = Patient.from_dict(raw_patient_data)
		patient_queue.append(patient)
		_add_unique_patient(all_patients_seen, patient)

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


func treat_current_patient_with_herbs(recipe_name: String, outcome: String) -> Patient.HealthState:
	if current_patient == null:
		return Patient.HealthState.WAITING

	var treated_patient := current_patient
	var result: Patient.HealthState = treated_patient.apply_herbal_treatment(recipe_name, outcome)

	_add_unique_patient(treated_patients, treated_patient)

	if result == Patient.HealthState.DEAD:
		_add_unique_patient(dead_patients, treated_patient)

	current_patient = null
	call_next_patient()

	return result


func refuse_current_patient() -> void:
	if current_patient == null:
		return

	var refused_patient := current_patient
	refused_patient.current_health_state = Patient.HealthState.WORSENED
	refused_patient.was_treated = false
	refused_patient.is_waiting = false

	_add_unique_patient(refused_patients, refused_patient)

	current_patient = null
	call_next_patient()


func progress_all_patients() -> void:
	for patient in patient_queue:
		_progress_patient(patient)

	if current_patient != null:
		_progress_patient(current_patient)


func has_current_patient() -> bool:
	return current_patient != null


func has_any_living_patient_seen() -> bool:
	for patient in all_patients_seen:
		if patient.current_health_state != Patient.HealthState.DEAD:
			return true

	return false


func get_unresolved_patients() -> Array[Patient]:
	var patients: Array[Patient] = []

	for patient in patient_queue:
		patients.append(patient)

	if current_patient != null:
		patients.append(current_patient)

	return patients


func get_queue_count() -> int:
	return patient_queue.size()


func get_treated_count() -> int:
	return treated_patients.size()


func get_refused_count() -> int:
	return refused_patients.size()


func get_dead_count() -> int:
	return dead_patients.size()


func get_resolved_count() -> int:
	return treated_patients.size() + refused_patients.size()


func get_total_known_patients_count() -> int:
	return all_patients_seen.size()


func get_total_campaign_patients_count() -> int:
	return total_campaign_patients


func get_survived_count() -> int:
	var count := 0

	for patient in all_patients_seen:
		if patient.current_health_state != Patient.HealthState.DEAD:
			count += 1

	return count


func get_patient_statistics() -> Dictionary:
	return {
		"treated": get_treated_count(),
		"refused": get_refused_count(),
		"dead": get_dead_count(),
		"resolved": get_resolved_count(),
		"waiting": get_queue_count(),
		"has_current_patient": has_current_patient(),
	}


func get_final_statistics() -> Dictionary:
	return {
		"total": get_total_campaign_patients_count(),
		"seen": get_total_known_patients_count(),
		"survived": get_survived_count(),
		"dead": get_dead_count(),
		"treated": get_treated_count(),
		"refused": get_refused_count(),
	}


func _progress_patient(patient: Patient) -> void:
	if patient == null:
		return

	patient.progress_disease()

	if patient.current_health_state == Patient.HealthState.DEAD:
		_add_unique_patient(dead_patients, patient)


func _add_unique_patient(target: Array[Patient], patient: Patient) -> void:
	if patient == null:
		return

	if not target.has(patient):
		target.append(patient)