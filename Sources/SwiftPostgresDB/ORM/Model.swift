//
//  Model.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//

import Foundation

/// Conform to `Model` for ORM mapping.
public protocol Model: Codable {
    static var tableName: String { get }
    var id: UUID? { get set }
}
