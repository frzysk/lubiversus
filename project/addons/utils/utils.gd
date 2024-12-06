extends Node

var _checking := []

func AsyncCondition(f: Callable) -> void:
	var s := Signal()
	_checking.append({"condition": f, "signal": s})
	await s
	
func _process(_delta: float) -> void:
	for v in _checking:
		if v["condition"].call():
			v["signal"].emit()
