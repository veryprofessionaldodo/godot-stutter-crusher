@tool
extends Node

signal updated_progress(new_progress: float)
signal finished_compiling

@export var scene_to_transition_to: PackedScene
@export var progress_bar: ProgressBar
@export var is_debug = false

var scenes_to_compile: Array[String] = []

var current_progress: float = 0.0
var debug_text: RichTextLabel

var parent_2d: Node
var parent_3d: Node

var total_nodes: int = 0
var processed_nodes: int = 0

var audio_streams = []
var debug_camera

func _enter_tree() -> void:
	debug_camera = Camera3D.new()
	add_child(debug_camera)
	add_child(OmniLight3D.new())
	
	if progress_bar:
		updated_progress.connect(progress_bar.set_value_no_signal)
	
	if is_debug:
		var ui = Control.new()
		ui.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(ui)
		
		debug_text = RichTextLabel.new()
		debug_text.set_anchors_preset(Control.PRESET_FULL_RECT)
		debug_text.scroll_following = true
		ui.add_child(debug_text)
		
		var button = Button.new()
		button.text = "Continue to first scene"
		button.connect("pressed", go_to_game)
		button.set_anchors_preset(Control.PRESET_CENTER)
		ui.add_child(button)
		
	# get all scenes
	await store_scene_paths("res://")
	
	# instantiate 2D node and 3D node that are going to be the fathers of 
	# all other nodes 
	parent_2d = Node2D.new()
	parent_3d = Node3D.new()
	add_child(parent_2d)
	add_child(parent_3d)

	# preprocess all scenes, and then add them to the actual scene
	var loaded_scenes = []
	for scene in scenes_to_compile:
		var new_scene = await preprocess_scene(scene)
		loaded_scenes.append(new_scene)
	
	for scene in loaded_scenes: 
		parent_3d.add_child(scene)
		await process_node(scene)
		
	go_to_game()
	
func store_scene_paths(path: String):
	var self_path = get_tree().current_scene.scene_file_path
	var resources = ResourceLoader.list_directory(path)
	
	for res in resources:
		# skip hidden folders
		if res[0] == '.': 
			continue
			
		var curr_path = path + res
		if res.ends_with("/"): 
			store_scene_paths(curr_path)
		elif res.ends_with('.tscn'): 
			if is_debug:
				debug_text.text += "Adding Scene to compile: " + curr_path + "\n"
			scenes_to_compile.append(curr_path)

# go through the instanced, but not added scene,
# see how many nodes there are, and make sure that 
# things like sound emitting nodes are muted
func preprocess_node(node: Node):
	if "visible" in node: 
		node.visible = false
		total_nodes += 1
	
	for child in node.get_children(true):
		await preprocess_node(child)
		
		if child is AudioStreamPlayer3D or child is AudioStreamPlayer2D: 
			audio_streams.append(child)

# actually go through the invisible nodes, and then toggle the visibility of them one by one
# have the camera be pointed to it to make sure it renders and triggers
func process_node(node: Node):
	if "visible" in node: 
		processed_nodes += 1
		node.visible = true
	
	await get_tree().create_timer(0.01).timeout
	var percent = (float(processed_nodes) / float(total_nodes)) * 100.0
	emit_signal("updated_progress", percent)
	print("processed nodes " + str(processed_nodes) + " total nodes " + str(total_nodes), " emitting " + str(percent))
	
	if node is Node3D:
		node.global_position = debug_camera.global_basis * Vector3.FORWARD * 10
		
	# if node is a particle systems, make it one shot and play it
	if node is CPUParticles2D or node is CPUParticles3D or node is GPUParticles2D or node is GPUParticles3D:
		node.one_shot = true
		node.emitting = true
		
	# if node has material with boolean shader parameters, toggle them one by one
	if node is MeshInstance3D:
		var base_material = node.mesh.surface_get_material(0)
		
	if is_debug:
		debug_text.text += "Processing node: " + node.name + ", processed " + str(processed_nodes) + " out of " + str(total_nodes) + " \n" 
		
	for child in node.get_children(true):
		await process_node(child)
	
	if "visible" in node: 
		node.visible = false

func preprocess_scene(scene: String): 
	var loaded_scene = load(scene).instantiate()
	preprocess_node(loaded_scene)
	if loaded_scene is Node3D:
		if is_debug:
			debug_text.text += "Instancing Scene:" + loaded_scene.name + "\n"
			
	return loaded_scene

func delete_scene(scene: Node): 
	if is_debug:
		debug_text.text += "Deleting node:" + scene.name + "\n"

func go_to_game():
	get_tree().change_scene_to_packed(scene_to_transition_to)
	
func _process(delta: float) -> void:
	# force all audio to be muted 
	for audio_stream in audio_streams:
		audio_stream.playing = false
		audio_stream.volume_db = 0
