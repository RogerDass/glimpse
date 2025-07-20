//
//  MetalView.swift
//  ShaderExample
//
//  Created by Roger D on 2025-07-07.
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
	let renderer: Glimpse.Renderer

	class Coordinator: NSObject, MTKViewDelegate {
		let renderer: Glimpse.Renderer

		init(renderer: Glimpse.Renderer) {
			self.renderer = renderer
			super.init()
		}

		func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
			// updates based on view size
		}

		func draw(in view: MTKView) {
			renderer.drawFrame(in: view)
		}
	}

	func makeCoordinator() -> MetalView.Coordinator {
		return MetalView.Coordinator(renderer: renderer)
	}

	#if os(iOS) || os(tvOS)
	func makeUIView(context: Context) -> MTKView {
		let view = MTKView()
		view.device = renderer.device
		view.delegate = context.coordinator
		view.colorPixelFormat = .rgba16Float
		view.clearColor = .init(red:0, green:0, blue:0, alpha:1)
		view.isPaused = false
		view.enableSetNeedsDisplay = false
		return view
	}

	func updateUIView(_ uiView: MTKView, context: Context) { }
	#elseif os(macOS)
	func makeNSView(context: Context) -> MTKView {
		let view = MTKView()
		view.device = renderer.device
		view.delegate = context.coordinator
		view.colorPixelFormat = .rgba16Float
		view.clearColor = .init(red:0, green:0, blue:0, alpha:1)
		view.isPaused = false
		view.enableSetNeedsDisplay = false
		return view
	}

	func updateNSView(_ nsView: MTKView, context: Context) { }
	#endif
}
