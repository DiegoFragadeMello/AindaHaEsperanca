class_name FamilyManager
extends Node

signal family_changed(members: Dictionary)
signal family_member_changed(member_id: String, member_data: Dictionary)

const DEFAULT_FAMILY_PATH := "res://data/characters/family.json"

var members: Dictionary = {}


func reset() -> void:
	load_from_json(DEFAULT_FAMILY_PATH)


func load_from_json(path: String = DEFAULT_FAMILY_PATH) -> void:
	var data := JsonDataLoader.load_json(path)
	members = data.get("members", {}).duplicate(true)
	family_changed.emit(get_snapshot())


func get_member(member_id: String) -> Dictionary:
	return members.get(member_id, {}).duplicate(true)


func has_member(member_id: String) -> bool:
	return members.has(member_id)


func set_member_value(member_id: String, key: String, value) -> void:
	if not members.has(member_id):
		push_warning("Familiar não encontrado: %s" % member_id)
		return

	members[member_id][key] = value
	family_member_changed.emit(member_id, get_member(member_id))
	family_changed.emit(get_snapshot())


func change_health(member_id: String, amount: int) -> void:
	if not members.has(member_id):
		push_warning("Familiar não encontrado: %s" % member_id)
		return

	var current_health := int(members[member_id].get("health", 0))
	members[member_id]["health"] = clamp(current_health + amount, 0, 100)

	if int(members[member_id]["health"]) <= 20:
		members[member_id]["state"] = "grave"
	elif int(members[member_id]["health"]) <= 50:
		members[member_id]["state"] = "frágil"

	family_member_changed.emit(member_id, get_member(member_id))
	family_changed.emit(get_snapshot())


func change_trust(member_id: String, amount: int) -> void:
	if not members.has(member_id):
		push_warning("Familiar não encontrado: %s" % member_id)
		return

	var current_trust := int(members[member_id].get("trust", 50))
	members[member_id]["trust"] = clamp(current_trust + amount, 0, 100)
	family_member_changed.emit(member_id, get_member(member_id))
	family_changed.emit(get_snapshot())


func get_snapshot() -> Dictionary:
	return members.duplicate(true)


func load_snapshot(data: Dictionary) -> void:
	members = data.duplicate(true)
	family_changed.emit(get_snapshot())
