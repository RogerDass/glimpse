//
//  ModelLoader.swift
//  Glimpse
//
//  Created by Roger D on 2025-04-29.
//
import Metal
import MetalKit
import ModelIO

public struct LoadedModel {
	public let meshes: [MTKMesh]
	public let mdlMeshes: [MDLMesh]
}

public enum ModelLoader {
	public static func load(
		named name: String,
		in bundle: Bundle = .main,
		device: MTLDevice
	) throws -> LoadedModel
	{
		// 1. Try each extension in priority order
		let exts = ["usdz", "usd", "obj"]
		let url: URL
		if let found = exts
			.lazy
			.compactMap({ bundle.url(forResource: name, withExtension: $0) })
			.first
		{
			url = found
		} else {
			throw NSError(
			  domain: "ModelLoader",
			  code: 1,
			  userInfo: [NSLocalizedDescriptionKey:
						 "Model \(name) not found (tried \(exts.joined(separator: ",")))."]
			)
		}

		// 2. Prepare allocator + vertex layout that matches your Metal shaders
		let allocator = MTKMeshBufferAllocator(device: device)


		let stride =
			MemoryLayout<SIMD3<Float>>.stride      // pos (12)
			+ MemoryLayout<SIMD3<Float>>.stride    // nrm (12)
			+ MemoryLayout<SIMD2<Float>>.stride    // uv  (8)
			// = 32 bytes ‑ aligned on 16 so Metal is happy

		let mdl = MDLVertexDescriptor()
		mdl.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
			format: .float3,
			offset: 0,
			bufferIndex: 0)
		
		mdl.attributes[1] = MDLVertexAttribute(
			name: MDLVertexAttributeNormal,
			format: .float3,
			offset: 12,
			bufferIndex: 0)

		mdl.attributes[2] = MDLVertexAttribute(
			name: MDLVertexAttributeTextureCoordinate,
			format: .float2,
			offset: 24,
			bufferIndex: 0)

		mdl.layouts[0] = MDLVertexBufferLayout(stride: stride)

		// 3. Load the asset **synchronously**
		let asset = MDLAsset(
			url: url,
			vertexDescriptor: mdl,
			bufferAllocator: allocator
		)
		asset.loadTextures()               // optional but handy


		// 4. Convert every MDLMesh → MTKMesh in one shot
		let (mdlMeshes, mtkMeshes) = try MTKMesh.newMeshes(asset: asset, device: device)

		guard !mdlMeshes.isEmpty else {
			throw NSError(domain: "ModelLoader", code: 2,
						  userInfo: [NSLocalizedDescriptionKey: "No meshes found in \(name)"])
		}

		return LoadedModel(meshes: mtkMeshes, mdlMeshes: mdlMeshes)

	}
}

