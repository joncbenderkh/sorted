extends Control

@onready var _title: Label = $Title


func _ready() -> void:
	_title.text = "Sorted %s" % Version.CURRENT
