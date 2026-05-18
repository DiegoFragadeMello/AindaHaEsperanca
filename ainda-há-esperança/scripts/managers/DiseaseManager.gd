class_name DiseaseManager
extends Node

signal diseases_loaded(diseases: Dictionary)

const DEFAULT_DISEASES_PATH := "res://data/characters/diseases.json"

var diseases: Dictionary = {}


func load_from_json(path: String = DEFAULT_DISEASES_PATH) -> void:
	var data := JsonDataLoader.load_json(path)
	diseases = data.get("diseases", {})
	diseases_loaded.emit(get_snapshot())


func get_snapshot() -> Dictionary:
	return diseases.duplicate(true)


func has_disease(disease_name: String) -> bool:
	return diseases.has(_normalize_id(disease_name))


func get_disease(disease_name: String) -> Dictionary:
	return diseases.get(_normalize_id(disease_name), {})


func get_effect_for_combination(disease_name: String, combination: Dictionary) -> Dictionary:
	var disease_id := _normalize_id(disease_name)
	var disease_data: Dictionary = diseases.get(disease_id, {})
	var recipes: Dictionary = disease_data.get("recipes", {})
	var combination_key := get_combination_key(combination)

	if recipes.has(combination_key):
		return recipes[combination_key]

	return get_default_unknown_effect()


func get_default_unknown_effect() -> Dictionary:
	return {
		"display_name": "mistura desconhecida",
		"outcome": "bad",
	}


func get_combination_key(combination: Dictionary) -> String:
	var artemisia_amount := int(combination.get(ResourceManager.ARTEMISIA, 0))
	var valeriana_amount := int(combination.get(ResourceManager.VALERIANA, 0))
	var salvia_amount := int(combination.get(ResourceManager.SALVIA, 0))

	return "artemisia:%d|valeriana:%d|salvia:%d" % [
		artemisia_amount,
		valeriana_amount,
		salvia_amount,
	]


func _normalize_id(value: String) -> String:
	var normalized := value.to_lower()
	normalized = normalized.strip_edges()
	normalized = normalized.replace(" ", "_")
	normalized = normalized.replace("á", "a")
	normalized = normalized.replace("à", "a")
	normalized = normalized.replace("ã", "a")
	normalized = normalized.replace("â", "a")
	normalized = normalized.replace("é", "e")
	normalized = normalized.replace("ê", "e")
	normalized = normalized.replace("í", "i")
	normalized = normalized.replace("ó", "o")
	normalized = normalized.replace("ô", "o")
	normalized = normalized.replace("õ", "o")
	normalized = normalized.replace("ú", "u")
	normalized = normalized.replace("ç", "c")
	return normalized
