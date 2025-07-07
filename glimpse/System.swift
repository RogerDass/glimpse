//
//  System.swift
//  Glimpse
//
//  Created by Roger D on 2025-04-08.
//

public protocol System {
	func update(deltaTime: Float, ecs: ECS, sceneNodes: [SceneNode])
}

