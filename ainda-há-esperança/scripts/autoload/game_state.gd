extends Node

signal day_changed(new_day: int)
signal time_changed(current_hour: int)
signal diary_updated
signal resources_changed
signal family_changed
signal patient_changed(patient: Patient)

const PATIENTS_JSON_PATH := "res://data/characters/patients.json"
const FAMILY_JSON_PATH := "res://data/characters/family.json"

const DISEASES_JSON_PATH := "res://data/characters/diseases.json"


var diary_entries: Array[String] = []

var current_day_actions: Array[String] = []
var current_day_patient_results: Array[String] = []

var patient_manager: PatientManager
var resource_manager: ResourceManager
var time_manager: TimeManager
var family_manager: FamilyManager
var disease_manager: DiseaseManager

var current_day: int = 1
var current_hour: int = 7

var artemisia: int = 0
var valeriana: int = 0
var salvia: int = 0

var current_patient: Patient = null
var family: Dictionary = {}


func _ready() -> void:
	_setup_managers()
	disease_manager.load_from_json(DISEASES_JSON_PATH)
	_sync_time_mirror()
	_sync_resources_mirror()
	_sync_family_mirror()


func _setup_managers() -> void:
	patient_manager = get_node_or_null("PatientManager") as PatientManager
	if patient_manager == null:
		patient_manager = PatientManager.new()
		patient_manager.name = "PatientManager"
		add_child(patient_manager)

	resource_manager = get_node_or_null("ResourceManager") as ResourceManager
	if resource_manager == null:
		resource_manager = ResourceManager.new()
		resource_manager.name = "ResourceManager"
		add_child(resource_manager)

	time_manager = get_node_or_null("TimeManager") as TimeManager
	if time_manager == null:
		time_manager = TimeManager.new()
		time_manager.name = "TimeManager"
		add_child(time_manager)

	family_manager = get_node_or_null("FamilyManager") as FamilyManager
	if family_manager == null:
		family_manager = FamilyManager.new()
		family_manager.name = "FamilyManager"
		add_child(family_manager)

	disease_manager = get_node_or_null("DiseaseManager") as DiseaseManager
	if disease_manager == null:
		disease_manager = DiseaseManager.new()
		disease_manager.name = "DiseaseManager"
		add_child(disease_manager)

	if not patient_manager.patient_changed.is_connected(_on_patient_changed):
		patient_manager.patient_changed.connect(_on_patient_changed)
	if not patient_manager.queue_empty.is_connected(_on_queue_empty):
		patient_manager.queue_empty.connect(_on_queue_empty)
	if not resource_manager.resources_changed.is_connected(_on_resources_changed):
		resource_manager.resources_changed.connect(_on_resources_changed)
	if not time_manager.day_changed.is_connected(_on_day_changed):
		time_manager.day_changed.connect(_on_day_changed)
	if not time_manager.time_changed.is_connected(_on_time_changed):
		time_manager.time_changed.connect(_on_time_changed)
	if not time_manager.night_started.is_connected(_on_night_started):
		time_manager.night_started.connect(_on_night_started)
	if not time_manager.game_days_finished.is_connected(_on_game_days_finished):
		time_manager.game_days_finished.connect(_on_game_days_finished)
	if not family_manager.family_changed.is_connected(_on_family_changed):
		family_manager.family_changed.connect(_on_family_changed)


func start_new_game() -> void:
	_setup_managers()

	time_manager.reset()
	resource_manager.reset()
	patient_manager.reset()
	family_manager.load_from_json(FAMILY_JSON_PATH)
	disease_manager.load_from_json(DISEASES_JSON_PATH)

	diary_entries.clear()
	current_day_actions.clear()
	current_day_patient_results.clear()

	_sync_time_mirror()
	_sync_resources_mirror()
	_sync_family_mirror()

	_load_patients_for_current_day()

	resources_changed.emit()
	family_changed.emit()

	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _load_patients_for_current_day() -> void:
	patient_manager.load_patients_from_json(current_day, PATIENTS_JSON_PATH)


func _on_patient_changed(patient: Patient) -> void:
	current_patient = patient
	patient_changed.emit(patient)


func _on_queue_empty() -> void:
	current_day_actions.append("Atendi todos os pacientes que chegaram até mim.")


func _on_resources_changed(_resources: Dictionary) -> void:
	_sync_resources_mirror()
	resources_changed.emit()


func _on_family_changed(_members: Dictionary) -> void:
	_sync_family_mirror()
	family_changed.emit()


func _on_day_changed(new_day: int) -> void:
	current_day = new_day
	day_changed.emit(new_day)


func _on_time_changed(new_hour: int) -> void:
	current_hour = new_hour
	time_changed.emit(new_hour)


func _on_night_started(_day_finished: int) -> void:
	end_day()


func _on_game_days_finished() -> void:
	end_game()


func _sync_time_mirror() -> void:
	if time_manager == null:
		return

	current_day = time_manager.current_day
	current_hour = time_manager.current_hour


func _sync_resources_mirror() -> void:
	if resource_manager == null:
		return

	artemisia = resource_manager.artemisia
	valeriana = resource_manager.valeriana
	salvia = resource_manager.salvia


func _sync_family_mirror() -> void:
	if family_manager == null:
		return

	family = family_manager.get_snapshot()


func treat_current_patient_with_combination(combination: Dictionary) -> void:
	if not patient_manager.has_current_patient():
		return

	var total_herbs := 0

	for herb_name in combination.keys():
		total_herbs += int(combination[herb_name])

	if total_herbs != 3:
		add_diary_entry("Tentei preparar uma mistura, mas errei a proporção. Preciso usar exatamente três porções de ervas.")
		return

	if not resource_manager.consume_herb_combination(combination):
		current_day_actions.append("Tentei preparar uma mistura, mas minhas ervas não foram suficientes.")
		add_diary_entry("Tentei preparar uma mistura, mas minhas ervas não foram suficientes.")
		return

	var patient: Patient = patient_manager.current_patient
	var effect_data := disease_manager.get_effect_for_combination(patient.disease_name, combination)

	var mixture_name := str(effect_data["display_name"])
	var outcome := str(effect_data["outcome"])

	var result: Patient.HealthState = patient_manager.treat_current_patient_with_herbs(mixture_name, outcome)

	current_day_actions.append(
		"Preparei %s para %s usando %s." % [
			mixture_name,
			patient.patient_name,
			_describe_combination(combination),
		]
	)

	_register_patient_result_by_outcome(patient, result, outcome)
	advance_time(3)


func _register_patient_result_by_outcome(patient: Patient, result: Patient.HealthState, outcome: String) -> void:
	match result:
		Patient.HealthState.RECOVERED:
			current_day_patient_results.append(
				"%s se recuperou após a mistura. Pela primeira vez no dia, senti que minhas mãos ainda podiam salvar alguém." % patient.patient_name
			)

		Patient.HealthState.STABILIZED:
			current_day_patient_results.append(
				"%s ficou estável. A doença não cedeu por completo, mas consegui afastá-la da beira do abismo." % patient.patient_name
			)

		Patient.HealthState.STABLE:
			current_day_patient_results.append(
				"%s permaneceu estável. Não sei se foi mérito da mistura ou simples sorte." % patient.patient_name
			)

		Patient.HealthState.WEAK:
			current_day_patient_results.append(
				"%s ficou debilitado. A mistura não parece ter sido suficiente." % patient.patient_name
			)

		Patient.HealthState.WORSENED:
			current_day_patient_results.append(
				"%s piorou depois do tratamento. Talvez eu tenha confundido os sinais da doença." % patient.patient_name
			)

		Patient.HealthState.CRITICAL:
			current_day_patient_results.append(
				"%s terminou em estado crítico. Passei o resto do dia temendo que não visse a manhã seguinte." % patient.patient_name
			)

		Patient.HealthState.DEAD:
			current_day_patient_results.append(
				"%s morreu sob meus cuidados. Escrevo seu nome aqui para que eu não esqueça o peso da minha escolha." % patient.patient_name
			)


func refuse_current_patient() -> void:
	if not patient_manager.has_current_patient():
		return

	var patient: Patient = patient_manager.current_patient
	patient_manager.refuse_current_patient()

	current_day_actions.append("Recusei atender %s." % patient.patient_name)
	current_day_patient_results.append(
		"%s partiu sem tratamento, e não sei se sobreviverá à noite." % patient.patient_name
	)

	advance_time(1)


func collect_herbs() -> void:
	resource_manager.collect_herbs()

	current_day_actions.append(
		"Saí para coletar ervas nos arredores da vila e trouxe um pouco de cada planta."
	)

	advance_time(2)


func rest() -> void:
	current_day_actions.append("Tentei descansar por algumas horas antes de continuar.")
	advance_time(2)


func advance_time(hours: int) -> void:
	time_manager.advance_time(hours)
	_sync_time_mirror()


func end_day() -> void:
	patient_manager.progress_all_patients()

	_register_waiting_patients_at_day_end()
	_write_day_summary(current_day)

	current_day_actions.clear()
	current_day_patient_results.clear()

	if current_day >= time_manager.max_days:
		_write_final_week_summary()
		get_tree().change_scene_to_file("res://scenes/diary.tscn")
		return

	if not time_manager.start_next_day():
		return

	_sync_time_mirror()
	_load_patients_for_current_day()

	get_tree().change_scene_to_file("res://scenes/diary.tscn")


func _register_waiting_patients_at_day_end() -> void:
	for patient in patient_manager.patient_queue:
		if patient.current_health_state == Patient.HealthState.DEAD:
			current_day_patient_results.append(
				"%s não resistiu enquanto aguardava atendimento." % patient.patient_name
			)
		else:
			current_day_patient_results.append(
				"%s terminou o dia ainda aguardando, em estado incerto." % patient.patient_name
			)

	if patient_manager.current_patient != null:
		var patient: Patient = patient_manager.current_patient

		if patient.current_health_state == Patient.HealthState.DEAD:
			current_day_patient_results.append(
				"%s morreu antes que eu pudesse decidir o que fazer." % patient.patient_name
			)
		else:
			current_day_patient_results.append(
				"%s permaneceu sem tratamento até o cair da noite." % patient.patient_name
			)


func _write_day_summary(day_finished: int) -> void:
	var text := "Diário - Dia %d\n\n" % day_finished
	text += "Hoje foi mais um dia pesado durante a peste.\n\n"

	if current_day_actions.is_empty():
		text += "Quase nada pude fazer. O silêncio da casa pesou mais do que os gritos da vila.\n\n"
	else:
		text += "Minhas ações:\n"
		for action in current_day_actions:
			text += "- %s\n" % action
		text += "\n"

	if current_day_patient_results.is_empty():
		text += "Nenhum paciente ficou sob meus cuidados hoje.\n"
	else:
		text += "Sobre os pacientes:\n"
		for result in current_day_patient_results:
			text += "- %s\n" % result

	text += "\nTermino o dia cansado, com as mãos manchadas pelo cheiro das ervas e pela dúvida do que fiz."

	add_diary_entry(text)


func get_resource(resource_name: String) -> int:
	return resource_manager.get_resource(resource_name)


func get_resources() -> Dictionary:
	return resource_manager.get_snapshot()


func get_family() -> Dictionary:
	return family_manager.get_snapshot()


func get_family_member(member_id: String) -> Dictionary:
	return family_manager.get_member(member_id)


func get_artemisia() -> int:
	return resource_manager.artemisia


func get_valeriana() -> int:
	return resource_manager.valeriana


func get_salvia() -> int:
	return resource_manager.salvia


func add_diary_entry(text: String) -> void:
	diary_entries.append(text)
	diary_updated.emit()


func get_save_data() -> Dictionary:
	return {
		"time": time_manager.get_snapshot(),
		"resources": resource_manager.get_snapshot(),
		"diary_entries": diary_entries,
		"family": family_manager.get_snapshot(),
	}


func load_save_data(data: Dictionary) -> void:
	_setup_managers()

	time_manager.load_snapshot(data.get("time", {}))
	resource_manager.load_snapshot(data.get("resources", {}))
	diary_entries.assign(data.get("diary_entries", []))
	family_manager.load_snapshot(data.get("family", {}))
	disease_manager.load_from_json(DISEASES_JSON_PATH)

	_sync_time_mirror()
	_sync_resources_mirror()
	_sync_family_mirror()

	_load_patients_for_current_day()

	diary_updated.emit()
	family_changed.emit()


func end_game() -> void:
	_write_final_week_summary()
	get_tree().change_scene_to_file("res://scenes/diary.tscn")



func _describe_combination(combination: Dictionary) -> String:
	var parts: Array[String] = []

	var artemisia_amount := int(combination.get(ResourceManager.ARTEMISIA, 0))
	var valeriana_amount := int(combination.get(ResourceManager.VALERIANA, 0))
	var salvia_amount := int(combination.get(ResourceManager.SALVIA, 0))

	if artemisia_amount > 0:
		parts.append("%d Artemísia-cinzenta" % artemisia_amount)

	if valeriana_amount > 0:
		parts.append("%d Raiz-de-valeriana" % valeriana_amount)

	if salvia_amount > 0:
		parts.append("%d Sálvia-da-febre" % salvia_amount)

	return ", ".join(parts)

func _write_final_week_summary() -> void:
	var dead_count := patient_manager.get_dead_count()
	var treated_count := patient_manager.get_treated_count()
	var refused_count := patient_manager.get_refused_count()
	var resolved_count := patient_manager.get_resolved_count()
	var score := _calculate_final_score(dead_count, refused_count)

	var text := "Diário - Fim da Semana\n\n"
	text += "Sete dias se passaram desde que comecei a atender os doentes desta vila.\n\n"

	text += "Ao reler estas páginas, encontro manchas de ervas, nomes riscados às pressas e decisões que talvez eu nunca consiga justificar.\n\n"

	text += "Ao todo, %d paciente(s) passaram pela porta do consultório durante esta semana.\n" % resolved_count
	text += "%d paciente(s) receberam algum tratamento.\n" % treated_count
	text += "%d paciente(s) foram recusados.\n" % refused_count
	text += "%d paciente(s) morreram.\n\n" % dead_count

	if dead_count == 0:
		text += "Nenhum dos que atendi morreu. Não sei se isso foi ciência, sorte ou misericórdia, mas hoje consigo respirar sem sentir o mesmo peso no peito.\n\n"
	elif dead_count <= 2:
		text += "Perdi alguns pacientes. Seus rostos ainda me acompanham quando fecho os olhos, mas também houve aqueles que resistiram por causa das minhas escolhas.\n\n"
	elif dead_count <= 4:
		text += "Muitos morreram. Eu continuei preparando misturas, anotando sintomas e fingindo firmeza, mas a verdade é que a peste venceu mais vezes do que eu.\n\n"
	else:
		text += "A semana terminou como uma confissão de fracasso. Enterrei mais nomes do que salvei, e cada mistura errada parece continuar presa às minhas mãos.\n\n"

	text += "Pontuação final: %d/100\n\n" % score
	text += "Se alguém encontrar este diário, que saiba: eu tentei. Mesmo quando já não tinha certeza se tentar ainda era suficiente."

	add_diary_entry(text)


func _calculate_final_score(dead_count: int, refused_count: int = 0) -> int:
	return clamp(100 - dead_count * 15 - refused_count * 5, 0, 100)