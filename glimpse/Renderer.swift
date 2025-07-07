//
//  Renderer.swift
//  Glimpse
//
//  Created by Roger D on 2025-03-13.
//

import Metal
import MetalKit
import simd

public class Renderer {
	public let device: MTLDevice
	private let commandQueue: MTLCommandQueue
	public var pipelineState: MTLRenderPipelineState
	public var pipelineStateModel: MTLRenderPipelineState
	public var vertexDescriptor: MTLVertexDescriptor
	public var vertexDescriptorModel: MTLVertexDescriptor

	public var ecs: ECS
	public var rootNode: SceneNode

	public var cameraMatrix: simd_float4x4 = matrix_identity_float4x4

	public var library: MTLLibrary


	public init?(device: MTLDevice) {
		self.device = device
		self.ecs = ECS()
		self.rootNode = SceneNode(name: "Root")

		guard let queue = device.makeCommandQueue() else { return nil }
		self.commandQueue = queue

		let frameworkBundle = Bundle(for: type(of: self))

		do {
			let bundleLib = try device.makeDefaultLibrary(bundle: frameworkBundle)
			print(bundleLib.functionNames)
			library = bundleLib
		} catch {
			print("Couldn't locate default library for bundle: \(frameworkBundle)")
			print( error )
			fatalError()
		}


		vertexDescriptor = MTLVertexDescriptor()
		vertexDescriptor.attributes[0].format = .float2
		vertexDescriptor.attributes[0].offset = 0
		vertexDescriptor.attributes[0].bufferIndex = 0
		vertexDescriptor.layouts[0].stride = MemoryLayout<simd_float2>.stride

		pipelineState = buildPipeline(
			device: device,
			vertex: "vertex_main", fragment: "fragment_main",
			vertexDescriptor: vertexDescriptor,
			library: library)


		// reuse vertex desc an repopulate for 3D model
		// POSITION (attribute 0)
		vertexDescriptorModel = MTLVertexDescriptor()
		vertexDescriptorModel.attributes[0].format = .float3
		vertexDescriptorModel.attributes[0].offset = 0
		vertexDescriptorModel.attributes[0].bufferIndex = 0

		// NORMAL (attribute 1)
		vertexDescriptorModel.attributes[1].format = .float3
		vertexDescriptorModel.attributes[1].offset = MemoryLayout<Float>.stride * 3
		vertexDescriptorModel.attributes[1].bufferIndex = 0

		// TEXCOORD_0 (attribute 2)
		vertexDescriptorModel.attributes[2].format = .float2
		vertexDescriptorModel.attributes[2].offset = MemoryLayout<Float>.stride * 6
		vertexDescriptorModel.attributes[2].bufferIndex = 0

		// Set stride of full vertex layout
		vertexDescriptorModel.layouts[0].stride = MemoryLayout<Float>.stride * 8
		vertexDescriptorModel.layouts[0].stepFunction = .perVertex

		pipelineStateModel = buildPipeline(
			device: device,
			vertex: "vertex_main_model", fragment: "fragment_main_model",
			vertexDescriptor: vertexDescriptorModel,
			library: library)
	}

	public func rebuildModelPipeline(with vd: MTLVertexDescriptor) {
		let pso = buildPipeline(
			device: device,
			vertex: "vertex_main_model", fragment: "fragment_main_model",
			vertexDescriptor: vd,
			library: library)

		pipelineStateModel = pso
		vertexDescriptorModel = vd         // keep a reference if you like
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

	///
	public func createEntitiesFromModel(
		_ model: LoadedModel,
		in renderer: Glimpse.Renderer,
		parent: SceneNode? = nil
	) {
		for (index, mesh) in model.meshes.enumerated() {
			let mdlMesh = model.mdlMeshes[index]

			// Register the entire MTKMesh once (for all its submeshes)
			let meshID = UUID()
			RenderComponent.registerMesh(id: meshID, mesh: .complex(mesh))

			for (submeshIndex, submesh) in mesh.submeshes.enumerated() {
				let entity = Entity()

				let transform = TransformComponent(translation: simd_float3.zero)

				let materialID = UUID()
				RenderComponent.registerMaterial(id: materialID, material: renderer.pipelineStateModel)

				let render = RenderComponent(meshID: meshID, materialID: materialID)

				let renderKey = RenderKey(meshID: meshID, materialID: materialID)
				let defaultColor = simd_float4(
					Float.random(in: 0.5...1.0),
					Float.random(in: 0.5...1.0),
					Float.random(in: 0.5...1.0),
					1.0
				)
				RenderComponent.instanceColors[renderKey, default: []].append(defaultColor)

				renderer.addEntity(entity, to: parent, with: [transform, render])
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


	public func updateCameraMatrix(for view: MTKView) {
		let aspect = Float(view.drawableSize.width / view.drawableSize.height)
		let eye = simd_float3(0, 0, 3)
		let center = simd_float3(0, 0, 0)
		let up = simd_float3(0, 1, 0)

		let viewMatrix = Glimpse.Math.lookAt(eye: eye, center: center, up: up)
		let projMatrix = Glimpse.Math.perspective(fovYRadians: 60 * .pi / 180, aspect: aspect, nearZ: 0.1, farZ: 100)

		self.cameraMatrix = projMatrix * viewMatrix
	}


	/// Pretty‑prints an MTLVertexDescriptor (or MTKMesh's vertexDescriptor)
	public func dumpVertexDescriptor(_ label: String, _ desc: MTLVertexDescriptor)
	{
		print("—— \(label) ——")

		// Attributes ------------------------------------------------------
		for i in 0..<31 {                               // Metal has 0–30 slots
			guard let a = desc.attributes[i],
				  a.format != .invalid else { continue }

			print(String(
				format: "  attr[%2d]  fmt %-8@  off %3d  buf %d",
				i, String(describing: a.format) as NSString, a.offset, a.bufferIndex
			))
		}

		// Layouts ---------------------------------------------------------
		for i in 0..<31 {
			guard let l = desc.layouts[i],
				  l.stride != 0 else { continue }

			print("  layout[\(i)]  stride \(l.stride)")
		}
		print("———————————————\n")
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

			guard let meshResource = RenderComponent.sharedMeshes[key.meshID] else {
				print("⚠️ Missing mesh for \(key.meshID)")
				continue
			}

			let material = RenderComponent.sharedMaterials[key.materialID]!

			encoder.setRenderPipelineState(material)

			var instanceBuffer = device.makeBuffer(
				bytes: transforms,
				length: transforms.count * MemoryLayout<simd_float4x4>.stride,
				options: []
			)!

			// Build and set instance color buffer
			let defaultWhite = SIMD4<Float>(1, 1, 1, 1)
			let colors = RenderComponent.instanceColors[key] ??
						 Array(repeating: defaultWhite, count: transforms.count)

			let colorBuffer = device.makeBuffer(bytes: colors,
												length: colors.count *
														MemoryLayout<SIMD4<Float>>.stride,
												options: [])!



			var uniforms = FrameUniforms(viewProjectionMatrix: cameraMatrix)
			let uniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<FrameUniforms>.stride, options: [])


			switch meshResource {
			case .simple(let buffer):
				// 2D quad (old code)
				encoder.setVertexBuffer(buffer, offset: 0, index: 0)
				encoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
				encoder.setVertexBuffer(colorBuffer, offset: 0, index: 2)
				encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 3)

				encoder.drawPrimitives(
					type: .triangleStrip,
					vertexStart: 0,
					vertexCount: 4,
					instanceCount: transforms.count
				)

			case .complex(let mtkMesh):
				for submesh in mtkMesh.submeshes {
					let vb = mtkMesh.vertexBuffers[0]
					encoder.setVertexBuffer(vb.buffer, offset: vb.offset, index: 0)
					encoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
					encoder.setVertexBuffer(colorBuffer, offset: 0, index: 2)
					encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 3)

					encoder.drawIndexedPrimitives(
						type: submesh.primitiveType,
						indexCount: submesh.indexCount,
						indexType: submesh.indexType,
						indexBuffer: submesh.indexBuffer.buffer,
						indexBufferOffset: submesh.indexBuffer.offset,
						instanceCount: transforms.count
					)
				}
			}
		}

		encoder.endEncoding()
		commandBuffer.present(drawable)
		commandBuffer.commit()
	}
}

