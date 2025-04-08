//
//  System.swift
//  TriangleExample
//
//  Created by Roger D on 2025-04-08.
//
import Glimpse

protocol System {
	func update(deltaTime: Float, ecs: ECS, sceneNodes: [SceneNode])
}

