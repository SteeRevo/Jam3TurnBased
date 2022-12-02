extends CanvasLayer

onready var bee := $BeeActor
onready var wasp := $WaspActor
onready var bee_health := $BeeActor/BeeHealth
onready var wasp_health := $WaspActor/WaspHealth
onready var label := $ActionLabel
onready var hit_anim = $HitAnim
onready var miss_anim = $MissAnim
onready var anim_player = $AnimationPlayer
onready var bee_sound = $BeeAttack
onready var wasp_sound = $WaspAttack
# ^ this is syntactic sugar for
#func _ready():
#  attacker = get_node("AttackerActor")
#  destination = get_node("Destination")

var attacker := bee
var target := wasp
var target_hlth := wasp_health
var endpoint := Vector2(0, 0)
var atkname := "BEE"

signal combat_ended

enum {PLAYER, ENEMY}

func _setup(attackingSide: int, y_offset: int, unitA: Unit, unitB: Unit):
	if attackingSide == PLAYER:
		attacker = bee
		target = wasp
		atkname = "BEE"
		endpoint = Vector2(target.position.x + 80, target.position.y + y_offset)
		bee_health.value = unitA.health
		bee_health.max_value = unitA.max_health
		wasp_health.max_value = unitB.max_health
	else:
		attacker = wasp
		target = bee
		atkname = "WASP"
		endpoint = Vector2(target.position.x - 80, target.position.y + y_offset)
		wasp_health.value = unitA.health
		wasp_health.max_value = unitA.max_health
		bee_health.max_value = unitB.max_health
	
	
func playHit(time: float, attackingSide: int, unitA: Unit, unitB: Unit, prev_health: int, new_health):
	hit_anim.visible = false
	miss_anim.visible = false
	_setup(attackingSide, 0, unitA, unitB)
	label.text = "%s Hit!" % atkname
	var action_tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	action_tween.tween_property(attacker, "global_position", endpoint, time)

	
	if (attackingSide == PLAYER):
		bee_sound.play()
		bee_sound.stop()
		wasp_health.value = prev_health
		yield(get_tree().create_timer(0.9), "timeout")
		$Tween.interpolate_property(wasp_health, "value", prev_health, unitB.health, 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		$Tween.start()
		#health_tween.tween_property(wasp_health, "", unitB.health, time)
	else:
		wasp_sound.play()
		wasp_sound.stop()
		bee_health.value = prev_health
		yield(get_tree().create_timer(0.9), "timeout")
		$Tween.interpolate_property(bee_health, "value", prev_health, unitB.health, 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		$Tween.start()
		
	#yield(get_tree().create_timer(0.4), "timeout")
	hit_anim.visible = true
	anim_player.play("Hit")
	
	
func playMiss(time: float, attackingSide: int, unitA: Unit, unitB: Unit):
	hit_anim.visible = false
	miss_anim.visible = false
	_setup(attackingSide, -200, unitA, unitB)
	if attackingSide == PLAYER:
		wasp_health.value = unitB.health
	else:
		bee_health.value = unitB.health
	
	label.text = "%s Missed!" % atkname
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	var dodge_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(attacker, "global_position", endpoint, time)
	dodge_tween.tween_property(target, "global_position", Vector2(target.position.x, target.position.y + 100), time)
	
	yield(get_tree().create_timer(1), "timeout")
	miss_anim.visible = true
	anim_player.play("Miss")
	yield(get_tree().create_timer(.5), "timeout")

