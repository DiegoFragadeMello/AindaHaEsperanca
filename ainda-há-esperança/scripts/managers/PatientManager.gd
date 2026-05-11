class_name PatientManager
extends Node

signal patient_changed(patient: Patient)
signal queue_empty

var current_patient: Patient = null
var patient_queue: Array[Patient] = []
var treated_patients: Array[Patient] = []
var dead_patients: Array[Patient] = []
var refused_patients: Array[Patient] = []


func reset() -> void:
	current_patient = null
	patient_queue.clear()
	treated_patients.clear()
	dead_patients.clear()
	refused_patients.clear()
	patient_changed.emit(null)


func load_patients_for_day(day_data: Array) -> void:
	patient_queue.clear()
	current_patient = null

	for data in day_data:
		if data is Patient:
			patient_queue.append(data)
		elif data is Dictionary:
			patient_queue.append(Patient.from_dict(data))
		else:
			push_warning("Dado de paciente inválido: %s" % str(data))

	call_next_patient()


func call_next_patient() -> Patient:
	if patient_queue.is_empty():
		current_patient = null
		patient_changed.emit(null)
		queue_empty.emit()
		return null

	current_patient = patient_queue.pop_front()
	current_patient.is_waiting = false
	patient_changed.emit(current_patient)
	return current_patient


func treat_current_patient(treatment_name: String, effectiveness: int) -> Patient.HealthState:
	if current_patient == null:
		return Patient.HealthState.STABLE

	var treated_patient := current_patient
	var result := treated_patient.apply_treatment(treatment_name, effectiveness)

	match result:
		Patient.HealthState.DEAD:
			dead_patients.append(treated_patient)
		_:
			treated_patients.append(treated_patient)

	current_patient = null
	call_next_patient()
	return result


func refuse_current_patient() -> void:
	if current_patient == null:
		return

	var refused_patient := current_patient
	refused_patient.current_health_state = Patient.HealthState.WORSE
	refused_patients.append(refused_patient)
	current_patient = null
	call_next_patient()


func progress_all_patients() -> void:
	for patient in patient_queue:
		patient.progress_disease()

	if current_patient != null:
		current_patient.progress_disease()


func get_queue_count() -> int:
	return patient_queue.size()


func get_treated_count() -> int:
	return treated_patients.size()


func get_dead_count() -> int:
	return dead_patients.size()


func get_refused_count() -> int:
	return refused_patients.size()


func has_current_patient() -> bool:
	return current_patient != null
