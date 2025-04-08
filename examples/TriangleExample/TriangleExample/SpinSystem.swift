//
//  SpinSystem.swift
//  TriangleExample
//
//  Created by Roger D on 2025-04-08.
//

import simd
import Glimpse

struct SpinSystem: System {
	func update(deltaTime: Float, ecs: ECS, sceneNodes: [SceneNode]) {
		for node in sceneNodes {
			guard let entity = node.entity else { continue }

			if var transform = ecs.getComponent(for: entity) as TransformComponent?,
			   let spin = ecs.getComponent(for: entity) as SpinComponent? {

				let rotation = GlimpseMath.float4x4_rotation(
					simd_quaternion(spin.speed * deltaTime, simd_float3(0, 0, 1))
				)
				transform.localTransform = transform.localTransform * rotation
				transform.applyToNode()
				ecs.addComponent(transform, to: entity)
			}
		}
	}
}
