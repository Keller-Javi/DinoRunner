extends Node

var SCORE_TO_NEW_BIOME : int = 100

var backgrounds: Array = []
var last_background
var new_background
var score_modifier : int = 0
var counter : float = .0

var grounds_list : Array = []

@onready var main := get_parent()
@onready var ground := main.get_node("Ground")

func _ready() -> void:
	score_modifier = main.SCORE_MODIFIER
	
	#Hago una lista para tener los fondos a mano
	backgrounds = [$Bg_mountain, $Bg_jungle, $Bg_desert]
	
	grounds_list = [ground.get_node("Mountain_Sprite"),
					ground.get_node("Jungle_Sprite"),
					ground.get_node("Desert_Sprite")]
	
	# Oculta todos los fondos al inicio
	for bg in backgrounds:
		bg.visible = false
	
	for gnd in grounds_list:
		gnd.visible = false
	
	# Activa un fondo de manera aleatoria
	main.biome = randi() % backgrounds.size()
	last_background = backgrounds[main.biome]
	ground = grounds_list[main.biome]
	
	last_background.visible = true
	ground.visible = true

func _process(delta: float) -> void:
	if main.score > 1 *score_modifier: 
		# Esto es para que no se cambie el fondo al inicio
		counter -= delta
		
		# Cambia el bioma al llegar a cierto puntaje
		if counter < 0 and ((main.score/score_modifier)%SCORE_TO_NEW_BIOME) == 0:
			counter = 0.5
			
			main.biome = randi() % backgrounds.size()
			new_background = backgrounds[main.biome]
			# Si el fondo es el mismo que está no hace nada
			if last_background != new_background:
				ground.visible = false
				ground = grounds_list[main.biome]
				ground.visible = true
				
				last_background.visible = false
				new_background.visible = true
				last_background = new_background
