extends CanvasLayer

onready var attacker = $AttackerActor
onready var hit_dest = $HitDest
onready var miss_dest = $MissDest
onready var label = $ActionLabel
# ^ this is syntactic sugar for
#func _ready():
#  attacker = get_node("AttackerActor")
#  destination = get_node("Destination")

func _ready():
	#playAttack()
	pass

func playHit(time: float):
	label.text = "Bee hit!"
	var tween := create_tween()
	tween.tween_property(attacker, "global_position", hit_dest.position, time)
	
func playMiss(time: float):
	label.text = "Bee missed!"
	var tween := create_tween()
	tween.tween_property(attacker, "global_position", miss_dest.position, time)

