//
//  ECS.swift
//  Glimpse
//
//  Created by Roger D on 2025-04-07.
//

import Foundation

public class ECS {
	private var components: [ObjectIdentifier: [UUID: Component]] = [:]

	// MARK: — Add / Get / Remove Single Component
	/// Add or overwrite a component on an entity.
	public func addComponent<T: Component>(_ component: T, to entity: Entity) {
		let key = ObjectIdentifier(T.self)
		var dict = components[key] ?? [:]
		dict[entity.id] = component
		components[key] = dict
	}

	/// Get one component of the given type, if present.
	public func getComponent<T: Component>(_ type: T.Type, for entity: Entity) -> T? {
		let key = ObjectIdentifier(T.self)
		return components[key]?[entity.id] as? T
	}

	/// Remove one component of the given type from an entity.
	public func removeComponent<T: Component>(_ type: T.Type, from entity: Entity) {
		let key = ObjectIdentifier(T.self)
		components[key]?[entity.id] = nil
	}


	// MARK: — Bulk / Entity-wide Operation
	// Remove all components from an entity.
	public func removeAllComponents(from entity: Entity) {
		for key in components.keys {
			components[key]?[entity.id] = nil
		}
	}

	/// Return all entities which have all of the specified component types.
	public func entities(with componentTypes: [Component.Type]) -> [Entity] {
		guard !componentTypes.isEmpty else { return [] }

		// Start with the set of IDs for the first type
		let firstKey = ObjectIdentifier(componentTypes[0])
		let firstMap = components[firstKey] ?? [:]
		var ids = Set(firstMap.keys)

		// Intersect with each subsequent type’s IDs
		for type in componentTypes.dropFirst() {
			let key = ObjectIdentifier(type)
			let map = components[key] ?? [:]
			let thisIDs = Set(map.keys)
			ids.formIntersection(thisIDs)
		}
		return ids.map { Entity(id: $0) }
	}

	/// Return every component of the given type across all entities.
	public func allComponents<T: Component>(of type: T.Type) -> [T] {
		let key = ObjectIdentifier(type)
		return components[key]?.values.compactMap { $0 as? T } ?? []
	}
}
