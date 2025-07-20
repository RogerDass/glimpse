//
//  Entity.swift
//  Glimpse
//
//  Created by Roger D on 2025-04-07.
//

import Foundation

public struct Entity: Hashable, Equatable {
	public let id: UUID

	public init() {
		self.id = UUID()
	}

	public init(id: UUID) {
		self.id = id
	}
}

