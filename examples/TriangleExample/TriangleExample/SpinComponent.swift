//
//  SpinComponent.swift
//  TriangleExample
//
//  Created by Roger D on 2025-04-08.
//

import simd
import Glimpse // <-- if needed for ECS/Component

public struct SpinComponent: Component {
	public var speed: Float
	public init(speed: Float) {
		self.speed = speed
	}
}
