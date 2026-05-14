class_name ResourceManager
extends Node

signal resource_changed(resource_name: String, new_value: int)
signal resources_changed(resources: Dictionary)

const ARTEMISIA := "artemisia"
const VALERIANA := "valeriana"
const SALVIA := "salvia"

const DEFAULT_ARTEMISIA := 10
const DEFAULT_VALERIANA := 10
const DEFAULT_SALVIA := 10

var artemisia: int = DEFAULT_ARTEMISIA
var valeriana: int = DEFAULT_VALERIANA
var salvia: int = DEFAULT_SALVIA


func reset() -> void:
	artemisia = DEFAULT_ARTEMISIA
	valeriana = DEFAULT_VALERIANA
	salvia = DEFAULT_SALVIA
	_emit_all_changed()


func get_resource(resource_name: String) -> int:
	match resource_name:
		ARTEMISIA:
			return artemisia
		VALERIANA:
			return valeriana
		SALVIA:
			return salvia
		_:
			push_warning("Erva desconhecida: %s" % resource_name)
			return 0


func set_resource(resource_name: String, value: int) -> void:
	value = max(value, 0)

	match resource_name:
		ARTEMISIA:
			artemisia = value
		VALERIANA:
			valeriana = value
		SALVIA:
			salvia = value
		_:
			push_warning("Erva desconhecida: %s" % resource_name)
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


func has_herb_combination(combination: Dictionary) -> bool:
	for herb_name in combination.keys():
		var amount := int(combination[herb_name])

		if not has_resource(herb_name, amount):
			return false

	return true


func consume_herb_combination(combination: Dictionary) -> bool:
	if not has_herb_combination(combination):
		return false

	for herb_name in combination.keys():
		var amount := int(combination[herb_name])
		consume_resource(herb_name, amount)

	return true


func collect_herbs() -> void:
	add_resource(ARTEMISIA, 1)
	add_resource(VALERIANA, 1)
	add_resource(SALVIA, 1)


func get_snapshot() -> Dictionary:
	return {
		ARTEMISIA: artemisia,
		VALERIANA: valeriana,
		SALVIA: salvia,
	}


func load_snapshot(data: Dictionary) -> void:
	artemisia = int(data.get(ARTEMISIA, DEFAULT_ARTEMISIA))
	valeriana = int(data.get(VALERIANA, DEFAULT_VALERIANA))
	salvia = int(data.get(SALVIA, DEFAULT_SALVIA))
	_emit_all_changed()


func _emit_all_changed() -> void:
	for resource_name in get_snapshot().keys():
		resource_changed.emit(resource_name, get_resource(resource_name))

	resources_changed.emit(get_snapshot())