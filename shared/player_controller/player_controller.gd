extends CharacterBody3D

enum State { WALK, SPRINT, JUMP }

@onready var camera := $Head/Camera3D
@onready var head := $Head

var current_speed := global.player_walk_speed
var current_state := State.WALK
var t_bob := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	#gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	#jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		change_state(State.JUMP)
	
	#sprint
	if Input.is_action_just_pressed("sprint"):
		toggle_state(State.WALK, State.SPRINT)
	
	#movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, global.player_sprint_speed * 2)
	var target_fov = global.camera_fov + global.camera_fov_multiply * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * global.player_camera_speed)
		camera.rotate_x(-event.relative.y * global.player_camera_speed * global.camera_fov_multiply)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * global.head_bob_freq) * global.head_bob_amp
	pos.x = cos(time * global.head_bob_freq  / 2) * global.head_bob_amp
	return pos

func change_state(state: State) -> void:
	current_state = state
	
	match current_state:
		State.WALK:
			current_speed = global.player_walk_speed
		State.SPRINT:
			current_speed = global.player_sprint_speed
		State.JUMP:
			velocity.y = global.player_jump_velocity
			change_state(State.WALK)

func toggle_state(base_state: State, toggled_state: State) -> void:
	if current_state == base_state:
		change_state(toggled_state)
	elif current_state == toggled_state:
		change_state(base_state)
