//
//  RenderComponent.swift
//  Glimpse
//
//  Created by Roger D on 2025-04-07.
//

import Metal
import MetalKit

public struct RenderKey: Hashable {
	public let meshID: UUID
	public let materialID: UUID

	public init(meshID: UUID, materialID: UUID) {
		self.meshID = meshID
		self.materialID = materialID
	}
}



public struct RenderComponent: Component {

	public enum MeshResource {
		case simple(MTLBuffer)
		case complex(MTKMesh)
	}

	static var sharedMeshes: [UUID: MeshResource] = [:]
	static var sharedMaterials: [UUID: MTLRenderPipelineState] = [:]
	public static var instanceColors: [RenderKey: [SIMD4<Float>]] = [:]

	public let meshID: UUID  // Reference to shared mesh
	public let materialID: UUID  // Reference to shared material

	public var meshResource: MeshResource {
		guard let mesh = RenderComponent.sharedMeshes[meshID] else {
			fatalError("❌ Mesh with ID \(meshID) not found.")
		}
		return mesh
	}

	public var simpleMesh: MTLBuffer? {
		if case let .simple(buffer) = meshResource {
			return buffer
		}
		return nil
	}

	public var complexMesh: MTKMesh? {
		if case let .complex(mtkMesh) = meshResource {
			return mtkMesh
		}
		return nil
	}


	public var material: MTLRenderPipelineState {
		guard let mat = RenderComponent.sharedMaterials[materialID] else {
			fatalError("❌ Material with ID \(materialID) not found.")
		}
		return mat
	}

	public init(meshID: UUID, materialID: UUID) {
		self.meshID = meshID
		self.materialID = materialID
	}

	public static func registerMesh(id: UUID, mesh: MeshResource) {
		sharedMeshes[id] = mesh
	}

	public static func registerMaterial(id: UUID, material: MTLRenderPipelineState) {
		sharedMaterials[id] = material
	}
}

