import SwiftUI
import MetalKit
import Glimpse

#if os(iOS) || os(tvOS)
	import UIKit
	typealias PlatformViewRepresentable = UIViewRepresentable
#elseif os(macOS)
	import AppKit
	typealias PlatformViewRepresentable = NSViewRepresentable
#endif

struct MetalView: PlatformViewRepresentable {

	class Coordinator: NSObject, MTKViewDelegate {
		let renderer: Glimpse.Renderer
		let mtkDevice: MTLDevice
		let systemManager = Glimpse.SystemManager()

		init?(renderer: Glimpse.Renderer) {
			self.renderer = renderer
			self.mtkDevice = renderer.device
			super.init()
		}

		func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
			// handle resize or projection updates
		}

		func update(deltaTime: Float) {
			let ecs = renderer.ecs
			let allNodes = renderer.getAllSceneNodes()

			systemManager.update(deltaTime: deltaTime, ecs: ecs, sceneNodes: allNodes)
		}

		func draw(in view: MTKView) {
			update(deltaTime: 1.0 / 60.0)
			renderer.drawFrame(in: view)
		}
	}


	func makeCoordinator() -> Coordinator {
		let device = MTLCreateSystemDefaultDevice()!
		guard let glimpseRenderer = Glimpse.Renderer(device: device) else {
			fatalError("Failed to create GlimpseRenderer")
		}

		guard let coord = Coordinator(renderer: glimpseRenderer) else {
			fatalError("Could not create coordinator")
		}

		// register our custom spin system
		coord.systemManager.add(SpinSystem())
		coord.systemManager.add(ColorPulseSystem())

		// === scene setup example ===
		// 1. Define & Register shared mesh
		let meshID = UUID()
		let v: Float = 0.02
		let vertices: [simd_float2] = [
			simd_float2(-v,  v),
			simd_float2( v,  v),
			simd_float2(-v, -v),
			simd_float2( v, -v)
		]
		let vertexBuffer = device.makeBuffer(
			bytes: vertices,
			length: vertices.count * MemoryLayout<simd_float2>.stride,
			options: []
		)!
		RenderComponent.registerMesh(id: meshID, mesh: .simple(vertexBuffer))

		// 2. Register shared material (reuse GlimpseRenderer's pipeline)
		let materialID = UUID()
		RenderComponent.registerMaterial(id: materialID, material: glimpseRenderer.pipelineState)

		// 3. get root node
		let rootNode = glimpseRenderer.rootNode

		// 4. Create entities with transforms and add to GlimpseRenderer
		let columns = 20
		let rows = 15
		let spacing: Float = 2.0 / Float(columns)

		for y in 0..<rows {
			for x in 0..<columns {
				let entity = Entity()

				let tx = (Float(x) - Float(columns) / 2.0) * spacing
				let ty = (Float(y) - Float(rows) / 2.0) * spacing

				let transform = TransformComponent(
					translation: simd_float3(tx, ty, 0)
				)

				let spin = SpinComponent(speed: Float.random(in: -Float.pi...Float.pi))

				let render = RenderComponent(meshID: meshID, materialID: materialID)

				let shouldPulse = Bool.random()
				if shouldPulse {
					let speed = Float.random(in: 1.0...3.0)
					let phase = Float.random(in: 0...(2 * .pi))
					let pulse = ColorPulseComponent(speed: speed, phase: phase)
					glimpseRenderer.addEntity(entity, to: rootNode, with: [transform, spin, pulse, render])
				}
				else {
					glimpseRenderer.addEntity(entity, to: rootNode, with: [transform, spin, render])
				}
			}
		}

		return coord
	}

#if os(iOS) || os(tvOS)
	func makeUIView(context: Context) -> MTKView {
		let view = MTKView()
		view.delegate = context.coordinator
		view.device = context.coordinator.mtkDevice
		view.colorPixelFormat = .rgba16Float
		view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
		view.enableSetNeedsDisplay = false
		view.isPaused = false
		return view
	}

	func updateUIView(_ uiView: MTKView, context: Context) {}

#elseif os(macOS)
	func makeNSView(context: Context) -> MTKView {
		let view = MTKView()
		view.delegate = context.coordinator
		view.device = context.coordinator.mtkDevice
		view.colorPixelFormat = .rgba16Float
		view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
		view.enableSetNeedsDisplay = false
		view.isPaused = false
		return view
	}

	func updateNSView(_ nsView: MTKView, context: Context) {}
#endif
}
