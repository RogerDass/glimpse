//
//  ShaderEditorViewModel.swift
//  ShaderExample
//
//  Created by Roger D on 2025-07-20.
//

import SwiftUI
import MetalKit
import Glimpse

class ShaderEditorViewModel: ObservableObject {
	@Published var shaderCode: String

	let renderer: Glimpse.Renderer
	let quadEntity: Entity
	let device: MTLDevice

	init() {
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

		// 4) Add one quad entity
		let e = Entity()
		let t = TransformComponent(translation: .zero)
		let rc = RenderComponent(meshID: meshID, materialID: matID)
		renderer.addEntity(e, to: renderer.rootNode, with: [t, rc])
		self.quadEntity = e

		// 5) initial shader text
		self.shaderCode = """
		#include <metal_stdlib>
		using namespace metal;

		vertex float4 vertex_main(uint vid [[vertex_id]]) {
			float2 P[4] = { {-1,-1},{+1,-1},{-1,+1},{+1,+1} };
			return float4(P[vid], 0, 1);
		}

		fragment float4 fragment_main() {
			return float4(1, 0.5, 0.2, 1);
		}
		"""
	}

	/// Compile and swap the shader
	func compileAndApplyShader() {
		do {
			let options = MTLCompileOptions()
			let lib = try device.makeLibrary(source: shaderCode, options: options)

			let pso = buildPipeline(
				device: device,
				vertex:   "vertex_main", fragment: "fragment_main",
				vertexDescriptor: renderer.vertexDescriptor,
				library:  lib
			)

			let newMatID = UUID()
			RenderComponent.registerMaterial(id: newMatID, material: pso)

			// overwrite the existing RenderComponent on quadEntity
			if let oldRC: RenderComponent = renderer.getComponent(RenderComponent.self, for: quadEntity) {
				let newRC = RenderComponent(meshID: oldRC.meshID, materialID: newMatID)
				renderer.addComponent(newRC, for: quadEntity)
			}
		}
		catch {
			print("Shader compile failed:", error)
		}
	}
}
