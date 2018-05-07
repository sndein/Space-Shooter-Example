extends RigidBody

# 0 to 1
var throttle = 0
# -1 to 1
var strafe = 0

var engine_state = "running"
var return_to_killed = false

var constant_drag = 1.0
export (float) var throttle_change = 2.0
export (float) var strafe_change = 15.0
export (float, 0, 1) var reverse_fraction = 0.5
export (float) var engine_drag
export (float) var max_force
export (float) var thruster_force
export (float) var strafe_force
export (Vector3) var steering_torque
export (Vector3) var angular_drag
export (Vector3) var rotation_inertia

#mouse joystick
var mouse_joy = Vector2()
var speed = 0
var mouselook = false

func _ready():
	global.set("current_camera", $CamTarget/Camera)
	global.set("player_ship", self)
	
func _physics_process(delta):
	get_mouse_joy()
	
	if Input.is_action_pressed("throttle_up"):
		engine_state = "running"
		throttle = throttle + throttle_change * delta
		if throttle > 1:
			throttle = 1
	if Input.is_action_pressed("throttle_down"):
		engine_state = "running"
		throttle = throttle - throttle_change * delta
		if throttle < 0:
			throttle = 0
	if Input.is_action_pressed("reverse_thrust"):
		throttle = -reverse_fraction
	if Input.is_action_just_released("reverse_thrust"):
		throttle = 0
	if Input.is_action_just_pressed("engine_toggle"):
		if engine_state == "running":
			engine_state = "killed"
		elif engine_state == "killed":
			engine_state = "running"
	if Input.is_action_just_pressed("mouselook_toggle"):
		if mouselook:
			mouselook = false
		else:
			mouselook = true
	if Input.is_action_pressed("strafe_left"):
		strafe = lerp(strafe, -1, strafe_change * delta)
	elif Input.is_action_pressed("strafe_right"):
		strafe = lerp(strafe, 1, strafe_change * delta)
	else:
		strafe = lerp(strafe, 0, strafe_change * delta)
		if abs(strafe) < 0.01:
			strafe = 0
	

# transforms mouse input into a Vector2 with values between -1 and 1 for joystick-like input
func get_mouse_joy():
	
	var viewport = get_viewport()
	var mouse_pos = viewport.get_mouse_position()
	
	var radii = Vector2(viewport.size.x, viewport.size.y) * 0.5
	
	var center = viewport.size * 0.5
	var offset = mouse_pos - center
	mouse_pos = offset / radii
	
	if mouse_pos.length() > 1:
		mouse_pos = mouse_pos.normalized()
	
	if Input.is_action_pressed("mouselook_activate") or mouselook:
		mouse_joy.x = mouse_pos.x
		mouse_joy.y = mouse_pos.y
	else:
		mouse_joy = Vector2()
		
func _integrate_forces(state):
	
	var applied_force = Vector3()
	var drag = Vector3()
	var engine_force
	
	if engine_state == "killed":
		if !Input.is_action_pressed("thruster") and abs(strafe) == 0 and !Input.is_action_pressed("reverse_thrust"):
			drag = -constant_drag * linear_velocity
		elif abs(strafe) != 0:
			#strafing input is present, engine is temporarily returned to running
			engine_force = max_force
			engine_state = "running"
			return_to_killed = true
		elif Input.is_action_pressed("thruster"):
			drag = -engine_drag * linear_velocity
			engine_force = max_force
			
			applied_force = global_transform.basis.xform(Vector3(0, 0, -thruster_force)) - global_transform.basis.z * engine_force
			state.add_force(applied_force, Vector3())
		else:
			engine_state = "running"
			return_to_killed = true
	
	if engine_state == "running":
		
		drag = -engine_drag * linear_velocity
		engine_force = throttle * max_force
		
		applied_force = -global_transform.basis.z * engine_force
		state.add_force(applied_force, Vector3())
		
		#thruster
		if Input.is_action_pressed("thruster"):

			applied_force = global_transform.basis.xform(Vector3(0, 0, -thruster_force))
			state.add_force(applied_force, Vector3())
		
		#strafing
		state.add_force(global_transform.basis.xform(Vector3(strafe, 0, 0) * strafe_force), Vector3())
		if return_to_killed == true and abs(strafe) == 0:
			engine_state = "killed"
			return_to_killed = false
	
	#adding drag
	state.add_force(drag, Vector3())
	
	speed = -transform.basis.xform_inv(linear_velocity).z
	
	#turning
	var ang_drag = -angular_drag * global_transform.basis.xform_inv(angular_velocity)
	
	var applied_torque = ang_drag + (Vector3(-mouse_joy.y, -mouse_joy.x, 0) * steering_torque)
	
	# should be equivalent to something like add_torque using my own inertia values
	angular_velocity += global_transform.basis.xform((Vector3(1.0, 1.0, 1.0) / rotation_inertia) * applied_torque) * state.step