# godot-stutter-crusher

A simple tool to precompile all Godot shaders, and fix initial stutters easily! Although you have the Shader Baker option for exports, this option isn't available for Compatibility projects, which include browser games. When doing game jams, this meant that the first minutes of gameplay were much more stuttery, especially in larger games. 

This is a quick solution that you can implement in 15 minutes, 

### Installation 

This tool is basicall a small script with a few properties you can manipulate. These are:
- Scene To Transition To: A `PackedScene` which represents your first scene, like your Main Menu for example;
- An optional `ProgressBar`: If you decide to have a progress bar on the shader compilation screen, the script automatically updates it's values as it is compiling;
- A debug `boolean`: If this is set, it shows on screen the nodes that are being processed at the moment, and includes a new "Continue to Initial Scene" button to skip shader compilation;

In order to add this to your project, you must first make your first scene a new one, where you're going to compile your shaders. An example of a simple one could be:
- One base `Node3D` to serve as the root. The script is associated with this node, and in it you can specify:
    - What scene you're going to transition to (effectively your first scene);
    - The scenes you want to compile
- One UI `Control` Node, with a `Full Rect` anchor mode. Inside it there is;
    - One background `ColorRect` to hide resources loading in the background. This should also be `Full Rect`;
    - One `Label` that you can modify, just serves as a way to tell the player that shaders are compiling;
    - One `ProgressBar` to give a visual indication of the current status of compilation.

To set your initial scene go to Project Settings > Application > Execute. 

### No AI was used to generate any code.