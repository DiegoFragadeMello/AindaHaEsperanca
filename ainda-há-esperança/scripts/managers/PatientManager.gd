class_name PatientManager
extends Node


# paciente atual

var current_patient : Patient = null


# fila de pacientes

var patient_queue : Array[Patient] = []


# histórico

var treated_patients : Array[Patient] = []

var dead_patients : Array[Patient] = []


# adicionar paciente

func add_patient(patient : Patient):

    patient_queue.append(patient)

    print(patient.patient_name + " added to queue.")


# chamar próximo paciente

func call_next_patient():

    if patient_queue.is_empty():

        current_patient = null

        print("No more patients.")

        return null


    current_patient = patient_queue.pop_front()

    current_patient.is_waiting = false

    print(current_patient.patient_name + " entered the office.")

    return current_patient


# remover paciente atual

func remove_current_patient():

    if current_patient == null:
        return


    print(current_patient.patient_name + " left the office.")

    current_patient = null


# tratar paciente atual

func treat_current_patient(treatment_name : String):

    if current_patient == null:
        return


    current_patient.apply_treatment(treatment_name)


    if current_patient.current_health_state == Patient.HealthState.RECOVERED:

        treated_patients.append(current_patient)

        print(current_patient.patient_name + " recovered.")

    elif current_patient.current_health_state == Patient.HealthState.DEAD:

        dead_patients.append(current_patient)

        print(current_patient.patient_name + " died.")


# examinar paciente atual

func examine_current_patient():

    if current_patient == null:
        return []


    return current_patient.examine()


# avançar doença de todos os pacientes

func progress_all_patients():

    for patient in patient_queue:

        patient.progress_disease()


    if current_patient != null:

        current_patient.progress_disease()


# verificar quantidade de pacientes

func get_patient_count() -> int:

    return patient_queue.size()


# verificar pacientes mortos

func get_dead_count() -> int:

    return dead_patients.size()


# verificar pacientes tratados

func get_treated_count() -> int:

    return treated_patients.size()


# limpar fila

func clear_queue():

    patient_queue.clear()

    current_patient = null

    print("Patient queue cleared.")