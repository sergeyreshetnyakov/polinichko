extends CharacterBody3D

enum State { WALK, SPRINT, JUMP}

@onready var camera := $Camera3D

var current_speed = global.player_walk_speed
var current_state = State.WALK

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * global.player_camera_speed)
		camera.rotate_x(-event.relative.y * global.player_camera_speed * global.player_camera_speed_y_multiplier)
		camera.rotation.x = clamp(camera.rotation.x, -1.2, 1.2)

func change_state(state: State) -> void:
	current_state = state
	
	match current_state:
		State.WALK:
			current_speed = global.player_walk_speed
		State.SPRINT:
			current_speed = global.player_sprint_speed
		State.JUMP:
			velocity.y = global.player_jump_velocity

func _physics_process(delta: float) -> void:
	#gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	#jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		change_state(State.JUMP)
	
	#sprint
	if Input.is_action_just_pressed("sprint"):
		print("sprint pressed")
		if current_state == State.WALK:
			change_state(State.SPRINT)
			print("changed sprint")
		elif current_state == State.SPRINT:
			change_state(State.WALK)
			print("changed walk")

	#movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
