//
//  SystemManager.swift
//  TriangleExample
//
//  Created by Roger D on 2025-04-08.
//
import Glimpse

final class SystemManager {
	private var systems: [System] = []

	func add(_ system: System) {
		systems.append(system)
	}

	func update(deltaTime: Float, ecs: ECS, sceneNodes: [SceneNode]) {
		for system in systems {
			system.update(deltaTime: deltaTime, ecs: ecs, sceneNodes: sceneNodes)
		}
	}
}

