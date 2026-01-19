# Stage

**Stage** est une bibliothèque graphique 3D développée en Zig. Fortement inspirée par la simplicité et la flexibilité de **Three.js**, **Stage** vise à fournir aux développeurs Zig une API intuitive pour manipuler des scènes, des caméras et des maillages (meshes) sans la complexité habituelle des API bas niveau.

## Dependencies

Pour compiler et utiliser **Stage**, vous devez avoir installé les éléments suivants :

* **Zig 0.15.2**
* **glfw3** (utilisé pour la gestion des fenêtres et des entrées)

## Quick Start

Voici un exemple minimal pour créer une scène et afficher un cube :

```zig
const stage = @import("stage");

pub fn main() !void {
    // Initialisation du moteur
    var app = try stage.App.init(.{
        .title = "Ma première scène 3D",
        .width = 800,
        .height = 600,
    });
    defer app.deinit();

    // Création de la scène et de la caméra
    var scene = stage.Scene.init();
    var camera = stage.PerspectiveCamera.init(75.0, 800.0/600.0, 0.1, 1000.0);
    camera.position.set(0, 0, 5);

    // Ajout d'un cube
    const geometry = stage.BoxGeometry.init(1, 1, 1);
    const material = stage.BasicMaterial.init(.{ .color = 0x00ff00 });
    var cube = stage.Mesh.init(geometry, material);
    
    scene.add(cube);

    // Boucle de rendu
    while (!app.shouldClose()) {
        cube.rotation.y += 0.01;
        try app.render(scene, camera);
    }
}

```

## Structure du Projet

* `/src/core` : Logique centrale (Scène, Object3D, Renderer).
* `/src/math` : Vecteurs, Matrices.
* `/src/geometries` : Primitives standards (Box, Sphere, Plane).
* `/src/materials` : Shaders et gestion des apparences.
* `/src/c` : C libraries.
