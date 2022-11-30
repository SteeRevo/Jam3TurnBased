extends CanvasLayer

onready var bee := $BeeActor
onready var wasp := $WaspActor
onready var label := $ActionLabel
# ^ this is syntactic sugar for
#func _ready():
#  attacker = get_node("AttackerActor")
#  destination = get_node("Destination")
var attacker := bee
var target := wasp
var endpoint := Vector2(0, 0)
var atkname := "BEE"

enum {PLAYER, ENEMY}

func _setup(attackingSide: int, y_offset: int):
	if attackingSide == PLAYER:
		attacker = bee
		target = wasp
		atkname = "BEE"
		endpoint = Vector2(target.position.x + 40, target.position.y + y_offset)
	else:
		attacker = wasp
		target = bee
		atkname = "WASP"
		endpoint = Vector2(target.position.x - 40, target.position.y + y_offset)
	
func playHit(time: float, attackingSide: int):
	_setup(attackingSide, 0)
	label.text = "%s Hit!" % atkname
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(attacker, "global_position", endpoint, time)
	
func playMiss(time: float, attackingSide: int):
	_setup(attackingSide, -40)
	label.text = "%s Missed!" % atkname
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(attacker, "global_position", endpoint, time)

