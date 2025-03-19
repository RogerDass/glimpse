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
	private let pipelineState: MTLRenderPipelineState
	private let vertexBuffer: MTLBuffer

	public init?(device: MTLDevice) {
		self.device = device

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
		pipelineDescriptor.colorAttachments[0].pixelFormat = .rgba16Float // TODO:: parametrize the pixel format

		do {
			self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
		} catch {
			print("Failed to create pipeline state: \(error)")
			return nil
		}

		// TODO: this is test. make more general and load geometry instead
		let v: Float = 0.9
		let vertices: [simd_float2] = [
			simd_float2(-v,  v),
			simd_float2( v,  v),
			simd_float2(-v, -v),
			simd_float2( v, -v)
		]
		let dataSize = vertices.count * MemoryLayout<simd_float2>.stride

		guard let buffer = device.makeBuffer(bytes: vertices, length: dataSize, options: []) else {
			return nil
		}
		self.vertexBuffer = buffer
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
		encoder.setRenderPipelineState(pipelineState)
		encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
		encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
		encoder.endEncoding()

		commandBuffer.present(drawable)
		commandBuffer.commit()
	}
}
