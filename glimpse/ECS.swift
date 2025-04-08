//
//  ECS.swift
//  Glimpse
//
//  Created by Roger D on 2025-04-07.
//

import Foundation

public class ECS {
	private var components: [ObjectIdentifier: [UUID: Component]] = [:]

	public func addComponent<T: Component>(_ component: T, to entity: Entity) {
		let id = ObjectIdentifier(T.self)
		components[id, default: [:]][entity.id] = component
	}

	public func getComponent<T: Component>(for entity: Entity) -> T? {
		let id = ObjectIdentifier(T.self)
		return components[id]?[entity.id] as? T
	}
}
