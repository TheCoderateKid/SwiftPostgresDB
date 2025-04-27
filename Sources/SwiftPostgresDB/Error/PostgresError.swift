//
//  PostgresError.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//

/// Descriptive error for PostgreSQL operations.
public struct PostgresError: Error, CustomStringConvertible {
    public let message: String
    public var description: String { message }
    public init(_ message: String) { self.message = message }
}
