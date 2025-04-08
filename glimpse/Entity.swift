//
//  Entity.swift
//  Glimpse
//
//  Created by Roger D on 2025-04-07.
//

import Foundation

public struct Entity {
	public let id: UUID

	public init(id: UUID = UUID()) {
		self.id = id
	}
}

