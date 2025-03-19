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
		let renderer: GlimpseRenderer
		let mtkDevice: MTLDevice

		init?(renderer: GlimpseRenderer) {
			self.renderer = renderer
			self.mtkDevice = renderer.device
			super.init()
		}

		func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
			// handle resize or projection updates
		}

		func draw(in view: MTKView) {
			renderer.drawFrame(in: view)
		}
	}

	func makeCoordinator() -> Coordinator {
		let device = MTLCreateSystemDefaultDevice()!
		guard let glimpseRenderer = GlimpseRenderer(device: device) else {
			fatalError("Failed to create GlimpseRenderer")
		}

		guard let coord = Coordinator(renderer: glimpseRenderer) else {
			fatalError("Could not create coordinator")
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
