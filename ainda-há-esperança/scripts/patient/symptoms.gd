class_name Symptoms
extends Resource


# informações básicas

@export var symptom_name : String = ""

@export_multiline var description : String = ""


# efeitos no paciente

@export var health_damage : int = 0

@export var stress_increase : int = 0

@export var infection_increase : int = 0


# comportamento

@export var visible : bool = true

@export var contagious_hint : bool = false

@export var severity : int = 1


# narrativa

@export var examination_text : String = ""

@export var diary_note : String = ""


# aplicar sintoma

func apply_symptom(patient):

    patient.health -= health_damage

    patient.stress += stress_increase

    patient.infection_level += infection_increase

    patient.update_health_state()


# informações do sintoma

func get_symptom_summary() -> Dictionary:

    return {
        "name": symptom_name,
        "severity": severity,
        "visible": visible
    }