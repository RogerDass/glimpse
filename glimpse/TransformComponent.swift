//
//  TransformComponent.swift
//  Glimpse
//
//  Created by Roger D on 2025-04-07.
//

import simd

public struct TransformComponent: Component {
	public var localTransform: simd_float4x4 = matrix_identity_float4x4
	public weak var node: SceneNode?  // Link to the Scene Graph

	public init(localTransform: simd_float4x4 = matrix_identity_float4x4,
				node: SceneNode? = nil) {
		self.localTransform = localTransform
		self.node = node
	}

	public init(translation: simd_float3 = .zero,
				rotation: simd_quatf = simd_quaternion(0, simd_float3(0, 1, 0)),
				scale: simd_float3 = simd_float3(repeating: 1),
				node: SceneNode? = nil) {
		let t = GlimpseMath.float4x4_translation(translation)
		let r = GlimpseMath.float4x4_rotation(rotation)
		let s = GlimpseMath.float4x4_scaling(scale)
		self.localTransform = t * r * s
		self.node = node
	}

	public var modelMatrix: simd_float4x4 {
		return node?.worldTransform ?? localTransform
	}
}

public extension TransformComponent {
	func applyToNode() {
		node?.transform = localTransform
	}
}

