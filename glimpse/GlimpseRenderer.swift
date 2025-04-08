//
//  Renderer.swift
//  Glimpse
//
//  Created by Roger D on 2025-03-13.
//

import Metal
import MetalKit
import simd

public class GlimpseRenderer {
	public let device: MTLDevice
	private let commandQueue: MTLCommandQueue
	public let pipelineState: MTLRenderPipelineState

	public var ecs: ECS
	public var rootNode: SceneNode

	public init?(device: MTLDevice) {
		self.device = device
		self.ecs = ECS()
		self.rootNode = SceneNode(name: "Root")

		guard let queue = device.makeCommandQueue() else { return nil }
		self.commandQueue = queue

		let frameworkBundle = Bundle(for: type(of: self))
		var library: MTLLibrary

		do {
			let bundleLib = try device.makeDefaultLibrary(bundle: frameworkBundle)
			print(bundleLib.functionNames)
			library = bundleLib
		} catch {
			print("Couldn't locate default library for bundle: \(frameworkBundle)")
			print( error )
			fatalError()
		}

		let vertexFunc = library.makeFunction(name: "vertex_main")
		let fragFunc   = library.makeFunction(name: "fragment_main")

		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.vertexFunction   = vertexFunc
		pipelineDescriptor.fragmentFunction = fragFunc
		pipelineDescriptor.colorAttachments[0].pixelFormat = .rgba16Float // TODO:: parametrize pixel format

		let vertexDescriptor = MTLVertexDescriptor()
		vertexDescriptor.attributes[0].format = .float2
		vertexDescriptor.attributes[0].offset = 0
		vertexDescriptor.attributes[0].bufferIndex = 0
		vertexDescriptor.layouts[0].stride = MemoryLayout<simd_float2>.stride
		pipelineDescriptor.vertexDescriptor = vertexDescriptor
		
		do {
			self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
		} catch {
			print("Failed to create pipeline state: \(error)")
			return nil
		}
	}

	

	/// Adds an entity to both the scene graph and ECS
	public func addEntity(_ entity: Entity, to parent: SceneNode? = nil, with components: [Component]) {
		let node = SceneNode(name: "Entity_\(entity.id)", entity: entity)
		(parent ?? rootNode).addChild(node)

		for var component in components {
			if var transform = component as? TransformComponent {
				transform.node = node
				transform.applyToNode()
				ecs.addComponent(transform, to: entity)
			} else {
				ecs.addComponent(component, to: entity)
			}
		}
	}

	/// Recursively updates scene graph before rendering
	public func updateSceneGraph(node: SceneNode) {
		for child in node.children {
			updateSceneGraph(node: child)
		}
	}

	/// Retrieves all nodes from the scene graph
	public func getAllSceneNodes() -> [SceneNode] {
		var allNodes: [SceneNode] = []
		func traverse(node: SceneNode) {
			allNodes.append(node)
			for child in node.children {
				traverse(node: child)
			}
		}
		traverse(node: rootNode)
		return allNodes
	}

	/// Called once per frame. Creates a command buffer, sets up the render pass,
	/// encodes the draw call, and commits to the GPU.
	///  Parameters:
	///   view: The MTKView whose drawable we’ll render into
	public func drawFrame(in view: MTKView) {
		guard
			let renderPassDescriptor = view.currentRenderPassDescriptor,
			let drawable = view.currentDrawable
		else {
			return
		}

		let commandBuffer = commandQueue.makeCommandBuffer()!
		let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

		updateSceneGraph(node: rootNode)

		// Group entities by mesh for instancing
		var instanceData: [RenderKey: [simd_float4x4]] = [:]


		for node in getAllSceneNodes() {

			if let entity = node.entity,
			   let transform = ecs.getComponent(for: entity) as TransformComponent?,
			   let render = ecs.getComponent(for: entity) as RenderComponent? {

				let key = RenderKey(meshID: render.meshID, materialID: render.materialID)
				instanceData[key, default: []].append(transform.modelMatrix)
			}
		}

		// Draw all instances
		for (key, transforms) in instanceData {
			let mesh = RenderComponent.sharedMeshes[key.meshID]!
			let material = RenderComponent.sharedMaterials[key.materialID]!

			encoder.setRenderPipelineState(material)
			encoder.setVertexBuffer(mesh, offset: 0, index: 0)

			var instanceBuffer = device.makeBuffer(
				bytes: transforms,
				length: transforms.count * MemoryLayout<simd_float4x4>.stride,
				options: []
			)!
			encoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)

			// Build and set instance color buffer
			let colors = RenderComponent.instanceColors[key] ?? []
			let colorBuffer = device.makeBuffer(
				bytes: colors,
				length: colors.count * MemoryLayout<simd_float4>.stride,
				options: []
			)!
			encoder.setVertexBuffer(colorBuffer, offset: 0, index: 2)

			encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: transforms.count)
		}

		encoder.endEncoding()
		commandBuffer.present(drawable)
		commandBuffer.commit()
	}
}

