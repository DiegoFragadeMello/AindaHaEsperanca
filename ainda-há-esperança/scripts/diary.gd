extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var diary_text: RichTextLabel = $MarginContainer/VBoxContainer/ScrollContainer/DiaryText
@onready var continue_button: Button = $MarginContainer/VBoxContainer/ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	_update_diary()


func _update_diary() -> void:
	title_label.text = "Diário"

	var full_text := ""

	for entry in GameState.diary_entries:
		full_text += entry
		full_text += "\n\n---\n\n"

	diary_text.text = full_text


func _on_continue_pressed() -> void:
	if GameState.current_day >= GameState.time_manager.max_days:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return

	get_tree().change_scene_to_file("res://scenes/main.tscn")