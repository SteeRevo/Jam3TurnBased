extends Control

onready var health_bar = $Healthbar
onready var health_label = $Label

func on_health_updated(health):
	health_bar.value = health
	health_label.text = str(health_bar.value)
	

func on_max_health_updated(max_health):
	health_bar.max_value = max_health
	health_bar.min_value = 1

