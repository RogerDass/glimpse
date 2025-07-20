//
//  ColorPulseSystem.swift
//  TriangleExample
//
//  Created by Roger D on 2025-04-08.
//

import simd
import QuartzCore
import Glimpse

struct ColorPulseSystem: System {
	
	func mix(_ a: Float, _ b: Float, _ t: Float) -> Float {
		return a * (1 - t) + b * t
	}
	
	func hsvToRgb(h: Float, s: Float, v: Float) -> simd_float4 {
		let c = v * s
		let x = c * (1 - abs(fmod(h * 6, 2) - 1))
		let m = v - c

		let (r, g, b): (Float, Float, Float)

		switch h {
		case 0..<1/6:  (r, g, b) = (c, x, 0)
		case 1/6..<1/3: (r, g, b) = (x, c, 0)
		case 1/3..<0.5: (r, g, b) = (0, c, x)
		case 0.5..<2/3: (r, g, b) = (0, x, c)
		case 2/3..<5/6: (r, g, b) = (x, 0, c)
		default:        (r, g, b) = (c, 0, x)
		}

		return simd_float4(r + m, g + m, b + m, 1.0)
	}


	func update(deltaTime: Float, ecs: ECS, sceneNodes: [SceneNode]) {
		// Clear previous frame's color data
		RenderComponent.instanceColors.removeAll(keepingCapacity: true)

		// Group entities by RenderKey
		var entitiesByKey: [RenderKey: [Entity]] = [:]

		for node in sceneNodes {
			guard let entity = node.entity else {continue}
			guard let render: RenderComponent = ecs.getComponent(RenderComponent.self, for: entity) else { continue }

			let key = RenderKey(meshID: render.meshID, materialID: render.materialID)
			entitiesByKey[key, default: []].append(entity)
		}

		// Animate pulse color
		let time = Float(CACurrentMediaTime())
		for (key, entities) in entitiesByKey {
			var colors: [simd_float4] = []

			for entity in entities {
				if let pulse: ColorPulseComponent = ecs.getComponent(ColorPulseComponent.self, for: entity) {
					let speed = max(0.1, pulse.speed)
					let hue = fmod(time * pulse.speed + pulse.phase, 1.0)
					let brightness = (sinf(time * 2.0 + pulse.phase)) // range ~0.4 → 1.0
					let color = SIMD4<Float>(brightness, brightness, 1.0, 1.0)
					colors.append(color)
				} else {
					colors.append(simd_float4(1, 1, 1, 1))
				}
			}

			RenderComponent.instanceColors[key] = colors
		}
	}
}
