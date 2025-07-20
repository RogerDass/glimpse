//
//  SceneNode.swift
//  Glimpse
//
//  Created by Roger D on 2025-04-07.
//

import simd

public class SceneNode {
	public var name: String
	public var transform: simd_float4x4
	public weak var parent: SceneNode?
	public var children: [SceneNode] = []

	public var entity: Entity?

	public init(name: String, entity: Entity? = nil, transform: simd_float4x4 = matrix_identity_float4x4) {
		self.name = name
		self.entity = entity
		self.transform = transform
	}

	public func addChild(_ child: SceneNode) {
		child.parent = self
		children.append(child)
	}

	public func removeChild(_ child: SceneNode) {
		children.removeAll { $0 === child }
		child.parent = nil
	}

	public func removeFromParent() {
		parent?.removeChild(self)
	}

	public var worldTransform: simd_float4x4 {
		return (parent?.worldTransform ?? matrix_identity_float4x4) * transform
	}
}
