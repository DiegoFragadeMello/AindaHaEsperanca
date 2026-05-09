```gdscript id="ajx8b4"
class_name Treatment
extends Resource


# informações básicas

@export var treatment_name : String = ""

@export_multiline var description : String = ""


# custo

@export var medicine_cost : int = 0

@export var energy_cost : int = 0

@export var time_cost : int = 1


# efeitos

@export var health_recovery : int = 20

@export var stress_reduction : int = 0

@export var infection_reduction : int = 20


# comportamento

@export var success_rate : int = 100

@export var risky : bool = false

@export var can_fail : bool = false


# narrativa

@export var unlocks_event : bool = false

@export var event_id : String = ""


# aplicar tratamento

func apply_treatment(patient):

    patient.health += health_recovery

    patient.stress -= stress_reduction

    patient.infection_level -= infection_reduction


    if patient.health > 100:
        patient.health = 100


    if patient.infection_level < 0:
        patient.infection_level = 0


    patient.update_health_state()


# verificar sucesso

func treatment_succeeded() -> bool:

    var roll = randi_range(1, 100)

    return roll <= success_rate


# informações do tratamento

func get_treatment_summary() -> Dictionary:

    return {
        "name": treatment_name,
        "medicine_cost": medicine_cost,
        "energy_cost": energy_cost,
        "time_cost": time_cost
    }
```
