# yaml -> json
conv_yaml_to_json() {
	"${PATA_DIR:-.}/thirdparty/yaml2json/yaml2json.py" "$@";
}
