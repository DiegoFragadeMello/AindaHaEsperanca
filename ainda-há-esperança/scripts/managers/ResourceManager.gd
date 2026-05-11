class_name ResourceManager
extends Node

signal resource_changed(resource_name: String, new_value: int)
signal resources_changed(resources: Dictionary)

const MEDICINE := "medicine"
const HERBS := "herbs"
const HOPE := "hope"
const FOOD := "food"
const MONEY := "money"

const DEFAULT_MEDICINE := 2
const DEFAULT_HERBS := 5
const DEFAULT_HOPE := 50
const DEFAULT_FOOD := 3
const DEFAULT_MONEY := 20

var medicine: int = DEFAULT_MEDICINE
var herbs: int = DEFAULT_HERBS
var hope: int = DEFAULT_HOPE
var food: int = DEFAULT_FOOD
var money: int = DEFAULT_MONEY


func reset() -> void:
	medicine = DEFAULT_MEDICINE
	herbs = DEFAULT_HERBS
	hope = DEFAULT_HOPE
	food = DEFAULT_FOOD
	money = DEFAULT_MONEY
	_emit_all_changed()


func get_resource(resource_name: String) -> int:
	match resource_name:
		MEDICINE:
			return medicine
		HERBS:
			return herbs
		HOPE:
			return hope
		FOOD:
			return food
		MONEY:
			return money
		_:
			push_warning("Recurso desconhecido: %s" % resource_name)
			return 0


func set_resource(resource_name: String, value: int) -> void:
	value = max(value, 0)

	match resource_name:
		MEDICINE:
			medicine = value
		HERBS:
			herbs = value
		HOPE:
			hope = value
		FOOD:
			food = value
		MONEY:
			money = value
		_:
			push_warning("Recurso desconhecido: %s" % resource_name)
			return

	resource_changed.emit(resource_name, value)
	resources_changed.emit(get_snapshot())


func add_resource(resource_name: String, amount: int) -> void:
	set_resource(resource_name, get_resource(resource_name) + amount)


func consume_resource(resource_name: String, amount: int = 1) -> bool:
	if amount <= 0:
		return true

	var current_value := get_resource(resource_name)
	if current_value < amount:
		return false

	set_resource(resource_name, current_value - amount)
	return true


func has_resource(resource_name: String, amount: int = 1) -> bool:
	return get_resource(resource_name) >= amount


func get_snapshot() -> Dictionary:
	return {
		MEDICINE: medicine,
		HERBS: herbs,
		HOPE: hope,
		FOOD: food,
		MONEY: money,
	}


func load_snapshot(data: Dictionary) -> void:
	medicine = int(data.get(MEDICINE, DEFAULT_MEDICINE))
	herbs = int(data.get(HERBS, DEFAULT_HERBS))
	hope = int(data.get(HOPE, DEFAULT_HOPE))
	food = int(data.get(FOOD, DEFAULT_FOOD))
	money = int(data.get(MONEY, DEFAULT_MONEY))
	_emit_all_changed()


func _emit_all_changed() -> void:
	var snapshot := get_snapshot()
	for resource_name in snapshot.keys():
		resource_changed.emit(resource_name, snapshot[resource_name])

	resources_changed.emit(snapshot)
