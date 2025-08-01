# Glimpse



## Introduction

Glimpse provides a lightweight Swift API library for 2D/3D visual effects/scenes. They help to setup a Metal pipeline, or easily integrate with an existing one without imposing a particular system or approach.

## Motivation

There are many frameworks, tools, etc. that aid in creating a 3D scene. Most notable are frameworks like RealityKit, Unity, etc.. Sometimes, a high fidelity, performant visual effect, or realtime 3D animation is desired in many places within an application, but integrating a large 3D rendering engine could be considered 'overkill'. Glimpse aims to assist in these scenarios by enabling convenience like math routines, 3D model loading, scene management, etc., while enabling infinite flexibility - since it does not provide much abstraction over bare Metal API calls.

## Proposed solution
To address these needs, Glimpse incorporates a entity-component-system architecture with scene graph, model loading and 3D math APIs at its core.

This enables Glimpse to function more like a game engine (ex. Unity) when it comes to ease of extensibility for custom logic.

3D models can be loaded with ease and then rendered with Physically-based lit materials and then composited together with screen-space effects and particle systems.

Due to the resulting scene being comprised only of swift code, it can easily be integrated into any application on any form factor.

## Example usage
Example projects using Glimpse can be found in the repo [here](https://github.com/RogerDass/glimpse/tree/main/examples)

#### Creating Drawable Entities
At the core of the built-in Entity-Component-System architecture is the ability to create entities in the 'scene' or 'world'.

```swift
// 1) Create renderer & device
self.device = MTLCreateSystemDefaultDevice()!
self.renderer = Glimpse.Renderer(device: device)!

// 2) Register a full-screen quad mesh
let meshID = UUID()
let v: Float = 1
let verts: [SIMD2<Float>] = [
	[-v, +v], [+v, +v],
	[-v, -v], [+v, -v]
]

let buf = device.makeBuffer(
	bytes: verts,
	length: verts.count * MemoryLayout<SIMD2<Float>>.stride,
	options: []
)!

RenderComponent.registerMesh(id: meshID, mesh: .simple(buf))

// 3) Default material
let matID = UUID()
RenderComponent.registerMaterial(id: matID, material: renderer.pipelineState)

// 4) Add an entity for mesh and assign transform and render components
let e = Entity()
let t = TransformComponent(translation: .zero)
let rc = RenderComponent(meshID: meshID, materialID: matID)
renderer.addEntity(e, to: renderer.rootNode, with: [t, rc])
self.quadEntity = e
```

#### Updating / Replacing Entity Components
An example of this could be replacing the renderable material/shader for a scene entity. In this case we could create and register a new material (Metal Pipeline state object), get the entity's render component and create a new one while replacing the material id with that of the new material. Adding the new render component to the same entity will overwrite the existing one.

```swift
func compileAndApplyShader() {
	do {
		let options = MTLCompileOptions()
		let lib = try device.makeLibrary(source: shaderCode, options: options)

		let pso = Glimpse.buildPipeline(
			device: device,
			vertex:   "vertex_main", fragment: "fragment_main",
			vertexDescriptor: renderer.vertexDescriptor,
			library:  lib
		)

		let newMatID = UUID()
		Glimpse.RenderComponent.registerMaterial(id: newMatID, material: pso)

		// overwrite the existing RenderComponent on quadEntity
		if let oldRC = renderer.getComponent(Glimpse.RenderComponent.self, for: quadEntity) {
			let newRC = Glimpse.RenderComponent(meshID: oldRC.meshID, materialID: newMatID)
			renderer.addComponent(newRC, for: quadEntity)
		}
	}
	catch {
		print("Shader compile failed:", error)
	}
}
```

#### Defining new Components and Systems
New behaviors can be added to the rendering engine by creating new components and systems.
We could introduce a random 'spin' component to entities as well as defining the system that reacts to those components.

```swift
public struct SpinComponent: Component {
	public var speed: Float
	public init(speed: Float) {
		self.speed = speed
	}
}
```
The protocol for System:

```swift
public protocol System {
	func update(deltaTime: Float, ecs: ECS, sceneNodes: [SceneNode])
}
```

Thus a corresponding system for `SpinComponent` could look like the following:

```swift
struct SpinSystem: System {
	func update(deltaTime: Float, ecs: ECS, sceneNodes: [SceneNode]) {
		for node in sceneNodes {
			guard let entity = node.entity else { continue }

			if var transform = ecs.getComponent(TransformComponent.self, for: entity),
			   let spin = ecs.getComponent(SpinComponent.self, for: entity) {

				let rotation = Glimpse.Math.float4x4_rotation(
					simd_quaternion(spin.speed * deltaTime, simd_float3(0, 0, 1))
				)
				transform.localTransform = transform.localTransform * rotation
				transform.applyToNode()
				ecs.addComponent(transform, to: entity)
			}
		}
	}
}
```

The custom systems can then be added to the `SystemManager`:

```swift
let device = MTLCreateSystemDefaultDevice()!
guard let renderer = Glimpse.Renderer(device: device) else {
	fatalError("Failed to create Renderer")
}

// register our custom spin system
renderer.systems.add(SpinSystem())
```

You can then assign the component to entities as follows:

```swift
let entity = Entity()

let tx = (Float(x) - Float(columns) / 2.0) * spacing
let ty = (Float(y) - Float(rows) / 2.0) * spacing

let transform = TransformComponent(
	translation: simd_float3(tx, ty, 0)
)

let spin = SpinComponent(speed: Float.random(in: -Float.pi...Float.pi))

let render = RenderComponent(meshID: meshID, materialID: materialID)

renderer.addEntity(entity, to: rootNode, with: [transform, spin, render])
```


#### Model loading
Instead of creating scene geometry from scratch, we can also load this from some popular model formats (ex. .USDZ, .OBJ). In this case, the extension is tried depending on the internal supported formats.

```swift

let device = MTLCreateSystemDefaultDevice()!
guard let renderer = Glimpse.Renderer(device: device) else {
	fatalError("Failed to create Renderer")
}

guard let coord = Coordinator(renderer: renderer) else {
	fatalError("Could not create coordinator")
}

// === scene setup example ===
let rootNode = renderer.rootNode

do {
	let model = try ModelLoader.load(named: "suzanne", in: .main, device: device)
	let pipelineVertexDesc = MTKMetalVertexDescriptorFromModelIO(model.meshes[0].vertexDescriptor)!

	// rebuild our metal pipeline to reflect model vertex layout
	renderer.rebuildModelPipeline(with: pipelineVertexDesc)

	renderer.createEntitiesFromModel(model, in: renderer, parent: rootNode)

} catch {
	print("Model load failed: \(error)")
}

```


#### Drawing
Continuing from the model loading snippet above, to draw:

```swift
func draw(in view: MTKView) {
	update(deltaTime: 1.0 / 60.0)
	renderer.updateCameraMatrix(for: view)
	renderer.drawFrame(in: view)
}

```

## Detailed design

#### `Renderer`
This is the main point of interaction from the application.

```swift
public let device: MTLDevice  // the passed in Metal device

public var pipelineState: MTLRenderPipelineState  // internal PSO for 2D geometry

public var pipelineStateModel: MTLRenderPipelineState // internal PSO for 3D geometry

public var vertexDescriptor: MTLVertexDescriptor // internal vertex desc for 2D geom.

public var vertexDescriptorModel: MTLVertexDescriptor // internal vertex desc for 3D geom.

public var systems: SystemManager  // the list of systems attached to the engine

public var rootNode: SceneNode // the root node of the scene entity hierarchy

public var cameraMatrix: simd_float4x4 = matrix_identity_float4x4

public var library: MTLLibrary // internal library which holds built-in shaders
```

```swift
// **-- Entity Lifecycle --**
	
/// Adds an entity to both the scene graph and ECS
public func addEntity(_ entity: Entity, to parent: SceneNode? = nil, with components: [Component])

/// Remove an entity completely: its SceneNode is detached from the graph,
/// and all its components are purged from the ECS.
public func removeEntity(_ entity: Entity)

/// walk through model hierarchy and create entities
public func createEntitiesFromModel(
	_ model: LoadedModel,
	in renderer: Glimpse.Renderer,
	parent: SceneNode? = nil
)


// **-- Component Accessors --**

/// Retrieve one of an entity’s components (nil if it isn’t present).
public func getComponent<C: Component>(_ type: C.Type, for entity: Entity) -> C?

/// Add or overwrite a component on an entity.
public func addComponent<C: Component>(_ component: C, for entity: Entity)

/// Remove a specific component type from an entity.
public func removeComponent<C: Component>(of type: C.Type, from entity: Entity)


// **-- Bulk Queries --**

/// Return all entities that have all of the given component types.
func entities< A: Component, B: Component >(with _: A.Type, _ : B.Type) -> [Entity]

/// Return all components of a given type across every entity.
func allComponents<C: Component>(of type: C.Type) -> [C]


// **-- Scene Graph --**

/// Recursively updates scene graph before rendering
public func updateSceneGraph(node: SceneNode)

/// Retrieves all nodes from the scene graph
public func getAllSceneNodes() -> [SceneNode]

/// Find the SceneNode corresponding to an entity by walking the graph.
private func findNode(for entity: Entity, in node: SceneNode) -> SceneNode?


// **-- Misc --**

/// rebuild the default 'model' pipeline state object based on new vertex desc.
public func rebuildModelPipeline(with vd: MTLVertexDescriptor)

/// Updates the internal camera matrix from MTKView dimensions
public func updateCameraMatrix(for view: MTKView)

/// Pretty‑prints an MTLVertexDescriptor (or MTKMesh's vertexDescriptor)
public func dumpVertexDescriptor(_ label: String, _ desc: MTLVertexDescriptor)

/// pre-draw updates (called once per frame)
public func update(deltaTime: Float) 

/// Called once per frame. Creates a command buffer, sets up the render pass,
/// encodes the draw call, and commits to the GPU.
///  Parameters:
///   view: The MTKView whose drawable we’ll render into
public func drawFrame(in view: MTKView)
```

#### `ECS`
The ECS class is private from the `Renderer` side, but when you subclass a `System` and you override `update()` you are passed in an instance of `ECS` to use for tight integration of your logic with `Renderer`'s.

```swift
// **-- Add / Get / Remove Single Component --**

/// Add or overwrite a component on an entity.
public func addComponent<T: Component>(_ component: T, to entity: Entity)

/// Get one component of the given type, if present.
public func getComponent<T: Component>(_ type: T.Type, for entity: Entity) -> T?

/// Remove one component of the given type from an entity.
public func removeComponent<T: Component>(_ type: T.Type, from entity: Entity)


// **-- Bulk / Entity-wide Operation --**

/// Remove all components from an entity.
public func removeAllComponents(from entity: Entity)

/// Return all entities which have all of the specified component types.
public func entities(with componentTypes: [Component.Type]) -> [Entity]

/// Return every component of the given type across all entities.
public func allComponents<T: Component>(of type: T.Type) -> [T]
```

## Impact on existing code
This is the first version of Glimpse, so there should not be any impact. There may be new interfaces presented in subsequent versions, but the aim is to keep these core ones presented here unchanged.

## Alternatives considered
Earlier, alternatives like RealityKit, Unity, and other rendering engines were considered. Ultimately, Glimpse aims to provide an even lighter weight, very thin - if any abstraction above Metal itself. This makes integrating the use of this toolkit into an existing codepath much less work. 
