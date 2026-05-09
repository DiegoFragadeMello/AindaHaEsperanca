class_name Disease
extends Resource


# informações básicas

@export var disease_name : String = ""

@export_multiline var description : String = ""


# sintomas

@export var symptoms : Array[String] = []


# tratamento

@export var correct_treatment : String = ""

@export var treatment_difficulty : int = 1


# progressão

@export var infection_rate : int = 10

@export var mortality_rate : int = 10

@export var health_decay : int = 15


# comportamento

@export var contagious : bool = false

@export var incubation_days : int = 0


# narrativa

@export var rarity : int = 1

@export var unlocks_story_event : bool = false

@export var story_event_id : String = ""


# consequências

@export var trust_impact : int = -5

@export var panic_impact : int = 10


# aplicar progressão

func progress(patient):

    if patient.current_health_state == patient.HealthState.DEAD:
        return

    patient.infection_level += infection_rate

    patient.health -= health_decay

    patient.update_health_state()


# verificar tratamento

func is_correct_treatment(treatment_name : String) -> bool:

    return treatment_name == correct_treatment


# resumo da doença

func get_disease_summary() -> Dictionary:

    return {
        "name": disease_name,
        "symptoms": symptoms,
        "treatment": correct_treatment,
        "mortality_rate": mortality_rate,
        "contagious": contagious
    }