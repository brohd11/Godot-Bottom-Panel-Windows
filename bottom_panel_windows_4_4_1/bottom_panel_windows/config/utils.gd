extends RefCounted


static func write_to_json(data:Variant,path:String,access=FileAccess.WRITE_READ) -> void:
	var data_string = JSON.stringify(data,"\t")
	var json_file = FileAccess.open(path, access)
	json_file.store_string(data_string)


static func read_from_json(path:String,access=FileAccess.READ) -> Dictionary:
	var json_read = JSON.new()
	var json_load = FileAccess.open(path, access)
	if json_load == null:
		print("Couldn't load JSON: ", path)
		return {}
	var json_string = json_load.get_as_text()
	var err = json_read.parse(json_string)
	if err != OK:
		print("Couldn't load JSON, error: ", err)
		return {}
	
	return json_read.data
