# Architecture
...

## Conception

const Vertex = struct {
    position: Position,
    color: Color
}

const Position = strcut {
    x: int,
    y: int,
    z: int,
}

const Color = struct {
    r: int,
    g: int,
    b: int,
}

cosnt Triangle = struct {
    vertecies: [3]Vertex,
}

const Geometry = struct {
    form: List<Triangle>
}

const Node = struct {
    value: Geometry
    matrix: [4][4]f32
    children: std:Arraylist<Node>

    fn (addChildren) {
        // Ajouter une enfant
    }
}

const GraphicTree = struct {
    node: Node,

    fn addNode() {
        // AJouter au sommet
    }
}

const Scene = struct {
    tree: GraphicTree,

    add(geometry) {
        tree.addNode(geometry)
    }
}

const App = struct {
    window: structGlfsWindows,


    fn render(scene) {
        scene.getProgram();
    }

}

Exemple d'utilisation:
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

    // Création de la scène
    var scene = stage.Scene.init();

    // Ajout d'un triangle
    const triangle = Geometry.Triangle;

    // Ajout à la scène
    scene.add(triangle)

    // Rendu
    app.render(scene)

    // app.animated(scene, fn) -- Pour plus tard
}

```