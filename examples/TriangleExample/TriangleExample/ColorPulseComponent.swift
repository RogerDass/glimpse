//
//  ColorPulseComponent.swift
//  TriangleExample
//
//  Created by Roger D on 2025-04-08.
//

import simd
import Glimpse

public struct ColorPulseComponent: Component {
	public var speed: Float     // frequency (Hz or radians/sec)
	public var phase: Float     // phase offset (randomized)

	public init(speed: Float, phase: Float) {
		self.speed = speed
		self.phase = phase
	}
}
