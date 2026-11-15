class_name QuizSession
extends RefCounted

var questions: Array = []
var index := 0
var score := 0
var selected := -1
var finished := false
var mistakes: Array[String] = []

func _init(items: Array = []) -> void:
	questions = items.duplicate(true)
	finished = questions.is_empty()

func current() -> Dictionary:
	return {} if finished else questions[index]

func answer(choice: int) -> bool:
	if finished or selected != -1 or choice < 0 or choice >= current().get("choices", []).size():
		return false
	selected = choice
	var correct: bool = choice == int(current()["correct"])
	if correct:
		score += 1
	else:
		var chapter: String = current().get("chapter", "")
		if chapter not in mistakes:
			mistakes.append(chapter)
	return correct

func advance() -> void:
	if finished or selected == -1:
		return
	index += 1
	selected = -1
	finished = index >= questions.size()
