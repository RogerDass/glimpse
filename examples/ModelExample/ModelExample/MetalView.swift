//
//  MetalView.swift
//  ModelExample
//
//  Created by Roger D on 2025-04-29.
//

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

		init?(renderer: Glimpse.Renderer) {
			self.renderer = renderer
			self.mtkDevice = renderer.device
			super.init()
		}

		func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
			// handle resize or projection updates
		}

		func update(deltaTime: Float) {
			//let ecs = renderer.ecs
			//let allNodes = renderer.getAllSceneNodes()
		}

		func draw(in view: MTKView) {
			update(deltaTime: 1.0 / 60.0)
			renderer.updateCameraMatrix(for: view)
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

		// === scene setup example ===
		let rootNode = glimpseRenderer.rootNode

		do {
			let model = try ModelLoader.load(named: "suzanne", in: .main, device: device)
			let pipelineVertexDesc = MTKMetalVertexDescriptorFromModelIO(model.meshes[0].vertexDescriptor)!

			// rebuild our metal pipeline to reflect model vertex layout
			glimpseRenderer.rebuildModelPipeline(with: pipelineVertexDesc)

			// test to see both model and metal pipelines are the same
			//glimpseRenderer.dumpVertexDescriptor("MTKMesh", pipelineVertexDesc)
			//glimpseRenderer.dumpVertexDescriptor("pipeline", glimpseRenderer.vertexDescriptorModel)

			glimpseRenderer.createEntitiesFromModel(model, in: glimpseRenderer, parent: rootNode)

		} catch {
			print("❌ Model load failed: \(error)")
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
