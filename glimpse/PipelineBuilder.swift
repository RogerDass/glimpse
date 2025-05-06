//
//  PipelineBuilder.swift
//  Glimpse
//
//  Created by Roger D on 2025-04-29.
//

import Metal
import MetalKit

public func buildPipeline(
	device: MTLDevice,
	vertex vertexFunctionName: String,
	fragment fragmentFunctionName: String,
	vertexDescriptor: MTLVertexDescriptor? = nil,
	pixelFormat: MTLPixelFormat = .rgba16Float,
	library: MTLLibrary? = nil
) -> MTLRenderPipelineState {
	do {
		let lib = library ?? device.makeDefaultLibrary()!
		let vertexFunction = lib.makeFunction(name: vertexFunctionName)!
		let fragmentFunction = lib.makeFunction(name: fragmentFunctionName)!

		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.vertexFunction = vertexFunction
		pipelineDescriptor.fragmentFunction = fragmentFunction
		pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat

		if let vertexDescriptor = vertexDescriptor {
			pipelineDescriptor.vertexDescriptor = vertexDescriptor
		}

		return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
	} catch {
		fatalError("❌ Failed to compile pipeline (\(vertexFunctionName)/\(fragmentFunctionName)): \(error)")
	}
}
