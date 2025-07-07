//
//  SystemManager.swift
//  Glimpse
//
//  Created by Roger D on 2025-04-08.
//

public final class SystemManager {
	private var systems: [System] = []

	public init() {}

	public func add(_ system: System) {
		systems.append(system)
	}

	public func update(deltaTime: Float, ecs: ECS, sceneNodes: [SceneNode]) {
		for system in systems {
			system.update(deltaTime: deltaTime, ecs: ecs, sceneNodes: sceneNodes)
		}
	}
}

