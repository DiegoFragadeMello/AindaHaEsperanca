class_name JsonDataLoader
extends RefCounted


static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Arquivo JSON não encontrado: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Não foi possível abrir o JSON: %s" % path)
		return {}

	var text := file.get_as_text()
	var json := JSON.new()
	var error := json.parse(text)

	if error != OK:
		push_error("Erro ao ler JSON em %s, linha %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("JSON inválido em %s. Era esperado um objeto/dicionário na raiz." % path)
		return {}

	return json.data


static func load_array(path: String) -> Array:
	var data := load_json(path)
	if data.has("items") and typeof(data["items"]) == TYPE_ARRAY:
		return data["items"]
	return []
