extends Node

var stump_scene = preload("res://scenes/obstacles/stump.tscn")
var rock_scene = preload("res://scenes/obstacles/rock.tscn")
var bush_scene = preload("res://scenes/obstacles/bush.tscn")
var flying_enemy_scene = preload("res://scenes/obstacles/flyingObstacle.tscn")
var obstacles_types := [stump_scene, rock_scene, bush_scene]
var obstacles : Array
var enemy_heights := [250, 385, 488] # ALTURA DE LOS ENEMIGOS

const DINO_START_POS := Vector2i(155, 503)
const CAM_START_POS := Vector2i(576, 324)
var dificulty
const MAX_DIFICULTY : int = 2
var score : int 
const SCORE_MODIFIER : int = 100
var high_score : int
var speed : float
const START_SPEED : float = 1000.0
const MAX_SPEED : int = 1500
const SPEED_MODIFIER : int = 100
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var last_obs

func _ready() -> void:
	# Load and update HUD of high score
	load_high_score()
	check_high_score()
	
	# Other inicializations
	screen_size = get_window().size 
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$GameOver/Button.pressed.connect(new_game)
	new_game()

func new_game():
	# Reset variables
	free_all_obstacles()

	obstacles = []
	score = 0
	speed = 0
	show_score()
	game_running = false
	dificulty = 0
	
	get_tree().paused = false
	
	# Hide gameover screen and free queue of obstacles
	$GameOver.hide()
	free_obs_queue()
	
	# Reset the nodes
	$Dino.position = DINO_START_POS
	$Dino.velocity = Vector2i(0,0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0,0)
	
	# Reset HUD
	$HUD/StartLabel.show()

func _process(delta: float) -> void:
	if game_running:
		# Speed up and adjust dificulty
		speed = clamp(START_SPEED + (score/SPEED_MODIFIER), START_SPEED, MAX_SPEED)
		adjust_dificulty()
		
		# Generate and clean obstacles
		generate_obs()
		free_obs_queue()
		
		# Move dino and camera
		$Dino.position.x += speed*delta
		$Camera2D.position.x += speed*delta
		
		# Update score
		score += speed*delta
		show_score()
		
		# Update ground position
		if ($Camera2D.position.x - $Ground.position.x) > screen_size.x*1.5:
			$Ground.position.x += screen_size.x
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD/StartLabel.hide()

func generate_obs():
	# Generate ground obstacles
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(200, 400):
		var obs_type = obstacles_types[randi() % obstacles_types.size()]
		var obs
		var max_obs = dificulty + 1 # Number of obstacles united in one
		for i in range(randi()%max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var cam_x = $Camera2D.position.x
			var obs_x : int = cam_x + screen_size.x + 200 + (i * 100)
			var obs_y : int = (screen_size.y - ground_height - (obs_height*obs_scale.y) + 5)
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		# Additionally random chance to spawn a flying enemy
		if dificulty == MAX_DIFICULTY:
			if (randi()%2 == 0):
				obs = flying_enemy_scene.instantiate()
				var cam_x = $Camera2D.position.x
				var obs_x : int = cam_x + screen_size.x + 200
				var obs_y : int = enemy_heights[(randi()%enemy_heights.size())]
				add_obs(obs, obs_x, obs_y)

func add_obs(obs,x,y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)
	obs.add_to_group("obstacle")

func hit_obs(body):
	if body.name == "Dino":
		game_over()

func free_obs_queue():
	for obs in obstacles:
			if obs.position.x < $Camera2D.position.x - screen_size.x:
				obs.queue_free()
				obstacles.erase(obs)

func show_score():
	$HUD/ScoreLabel.text = "SCORE: " + str(score / SCORE_MODIFIER)
	var show_speed : int = 0
	if speed != 0:
		show_speed = clamp((100*(speed-START_SPEED)/MAX_SPEED), 1, 100)
	$HUD/SpeedLabel.text = "SPEED: " + str(show_speed) + "%"

func adjust_dificulty():
	dificulty = clamp(score / (SPEED_MODIFIER*1000), 0, MAX_DIFICULTY)

func check_high_score():
	if score > high_score:
		high_score = score
		save_high_score()
	$HUD/HighScoreLabel.text = "HIGH SCORE: " + str(high_score / SCORE_MODIFIER)

func game_over():
	$Dino/hurtSound.play()
	check_high_score()
	get_tree().paused = true
	game_running = false
	$GameOver.show()

func save_high_score():
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	file.store_var(high_score)
	file.close()

func load_high_score():
	if FileAccess.file_exists("user://savegame.save"):
		var file = FileAccess.open("user://savegame.save", FileAccess.READ)
		high_score = file.get_var()
		file.close()
	else:
		high_score = 0

# nueva función para borrar absolutamente todos los obstáculos que queden en la escena
func free_all_obstacles() -> void:
	# Usamos el grupo "obstacle" (ver add_obs) para identificar los nodos a borrar
	var to_free := []
	# recolecto primero para evitar modificar la escena mientras la itero
	for child in get_children():
		if child.is_in_group("obstacle"):
			to_free.append(child)
	# ahora los libero
	for obs in to_free:
		if is_instance_valid(obs):
			obs.queue_free()

	# vaciamos la lista y reseteamos el puntero
	obstacles.clear()
	last_obs = null
