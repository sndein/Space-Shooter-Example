tool
extends Node

export (PackedScene) var object
export (int) var count
export (bool) var random_rotation
export (Vector2) var scale_range
export (int) var radius

func _ready():
	if object != null:
		for i in count:
			randomize()
			spawn_asteroid(i)

func spawn_asteroid(i):
	var spawn_position = Vector3()
	
	spawn_position.x = rand_range(-radius, radius)
	spawn_position.y = rand_range(-radius, radius)
	spawn_position.z = rand_range(-radius, radius)
	
	var asteroid = object.instance()
	
	asteroid.translation = spawn_position
	
	asteroid.scale = Vector3(rand_range(scale_range.x, scale_range.y), rand_range(scale_range.x, scale_range.y), rand_range(scale_range.x, scale_range.y))
	
	if random_rotation:
		asteroid.rotation = Vector3(randf(), randf(), randf())
	
	add_child(asteroid)
	
