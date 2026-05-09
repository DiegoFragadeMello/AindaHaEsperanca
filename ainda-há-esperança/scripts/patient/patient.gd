class_name Patient
extends Node


# identificação

@export var patient_name : String = "Unknown"
@export var age : int = 0
@export var occupation : String = ""
@export var description : String = ""


# doença

@export var disease_name : String = ""

@export var symptoms : Array[String] = []

@export var correct_treatment : String = ""


# estado do paciente

enum HealthState {
    STABLE,
    WORSENING,
    CRITICAL,
    DEAD,
    RECOVERED
}

var current_health_state : HealthState = HealthState.STABLE

@export var health : int = 100
@export var stress : int = 0
@export var infection_level : int = 0


# relacionamentos

@export var family_name : String = ""
@export var importance_level : int = 0

var trusts_doctor : int = 50


# narrativa

@export_multiline var introduction_dialogue : String = ""

@export_multiline var examination_dialogue : String = ""

@export_multiline var death_dialogue : String = ""

@export_multiline var cured_dialogue : String = ""


# controle

var was_treated : bool = false
var was_examined : bool = false
var is_waiting : bool = true


# ready

func _ready():
    update_health_state()


# examinar

func examine():

    was_examined = true

    print(patient_name + " was examined.")

    return symptoms


# tratamento

func apply_treatment(treatment_name : String):

    was_treated = true

    if treatment_name == correct_treatment:

        heal()

    else:

        worsen()


# cura

func heal():

    current_health_state = HealthState.RECOVERED

    health = 100

    print(patient_name + " recovered.")


# piora

func worsen():

    infection_level += 25
    health -= 30
    stress += 10

    update_health_state()

    print(patient_name + " condition worsened.")


# progressão da doença

func progress_disease():

    if current_health_state == HealthState.DEAD:
        return

    infection_level += 10
    health -= 15

    update_health_state()


# atualizar estado

func update_health_state():

    if health <= 0:

        die()

    elif health <= 25:

        current_health_state = HealthState.CRITICAL

    elif health <= 60:

        current_health_state = HealthState.WORSENING

    else:

        current_health_state = HealthState.STABLE


# morte

func die():

    current_health_state = HealthState.DEAD

    health = 0

    print(patient_name + " died.")


# informações

func get_patient_summary() -> Dictionary:

    return {
        "name": patient_name,
        "age": age,
        "disease": disease_name,
        "health": health,
        "state": current_health_state,
        "symptoms": symptoms,
        "treated": was_treated
    }