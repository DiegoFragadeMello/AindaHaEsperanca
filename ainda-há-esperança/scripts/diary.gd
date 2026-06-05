extends Control

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const MENU_SCENE_PATH := "res://scenes/menu.tscn"

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var diary_text: RichTextLabel = $MarginContainer/VBoxContainer/ScrollContainer/DiaryText
@onready var continue_button: Button = $MarginContainer/VBoxContainer/ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	_update_diary()


func _update_diary() -> void:
	title_label.text = GameState.get_diary_title()

	var entries := GameState.get_diary_entries_newest_first()

	if entries.is_empty():
		diary_text.text = "Nenhuma entrada escrita ainda."
		return

	diary_text.text = "\n\n---\n\n".join(entries)


func _on_continue_pressed() -> void:
	if GameState.game_finished:
		GameState.return_to_menu_after_game_over()
		return

	get_tree().change_scene_to_file(MAIN_SCENE_PATH)