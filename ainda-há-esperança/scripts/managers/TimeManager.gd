class_name TimeManager
extends Node

signal day_changed(new_day: int)
signal time_changed(current_hour: int)
signal night_started(day_finished: int)
signal game_days_finished

const DEFAULT_MAX_DAYS := 7
const DEFAULT_START_HOUR := 7
const DEFAULT_NIGHT_HOUR := 21

@export var max_days: int = DEFAULT_MAX_DAYS
@export var start_hour: int = DEFAULT_START_HOUR
@export var night_hour: int = DEFAULT_NIGHT_HOUR

var current_day: int = 1
var current_hour: int = DEFAULT_START_HOUR


func reset() -> void:
	current_day = 1
	current_hour = start_hour
	day_changed.emit(current_day)
	time_changed.emit(current_hour)


func advance_time(hours: int) -> void:
	if hours <= 0:
		return

	current_hour += hours

	if current_hour >= night_hour:
		night_started.emit(current_day)
	else:
		time_changed.emit(current_hour)


func start_next_day() -> bool:
	current_day += 1

	if current_day > max_days:
		game_days_finished.emit()
		return false

	current_hour = start_hour
	day_changed.emit(current_day)
	time_changed.emit(current_hour)
	return true


func force_end_day() -> void:
	night_started.emit(current_day)


func get_snapshot() -> Dictionary:
	return {
		"current_day": current_day,
		"current_hour": current_hour,
		"max_days": max_days,
		"start_hour": start_hour,
		"night_hour": night_hour,
	}


func load_snapshot(data: Dictionary) -> void:
	max_days = int(data.get("max_days", DEFAULT_MAX_DAYS))
	start_hour = int(data.get("start_hour", DEFAULT_START_HOUR))
	night_hour = int(data.get("night_hour", DEFAULT_NIGHT_HOUR))
	current_day = int(data.get("current_day", 1))
	current_hour = int(data.get("current_hour", start_hour))

	day_changed.emit(current_day)
	time_changed.emit(current_hour)
