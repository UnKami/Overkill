class_name StatusEffectData extends Resource

enum StackBehavior { INTENSITY, DURATION, BOTH }  ## Strength = intensity-stacking, Vulnerable = duration

@export var id: String = ""                     ## e.g. "vulnerable", "weak", "strength"
@export var display_name: String = ""
@export var stack_behavior: StackBehavior = StackBehavior.DURATION
@export var icon_id: String = ""                ## shared icon set, art doc Section E
@export_multiline var description_template: String = ""  ## e.g. "Takes {value}% more damage" - filled at render time
