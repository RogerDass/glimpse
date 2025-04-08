//
//  RenderComponent.swift
//  Glimpse
//
//  Created by Roger D on 2025-04-07.
//

import Metal

public struct RenderKey: Hashable {
	public let meshID: UUID
	public let materialID: UUID

	public init(meshID: UUID, materialID: UUID) {
		self.meshID = meshID
		self.materialID = materialID
	}
}


public struct RenderComponent: Component {
	static var sharedMeshes: [UUID: MTLBuffer] = [:]
	static var sharedMaterials: [UUID: MTLRenderPipelineState] = [:]
	public static var instanceColors: [RenderKey: [SIMD4<Float>]] = [:]

	public let meshID: UUID  // Reference to shared mesh
	public let materialID: UUID  // Reference to shared material

	public var mesh: MTLBuffer {
		return RenderComponent.sharedMeshes[meshID]!
	}

	public var material: MTLRenderPipelineState {
		return RenderComponent.sharedMaterials[materialID]!
	}

	public init(meshID: UUID, materialID: UUID) {
		self.meshID = meshID
		self.materialID = materialID
	}

	public static func registerMesh(id: UUID, mesh: MTLBuffer) {
		sharedMeshes[id] = mesh
	}

	public static func registerMaterial(id: UUID, material: MTLRenderPipelineState) {
		sharedMaterials[id] = material
	}
}

