//
//  TransactionManager.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//

import PostgresNIO

/// Manages database transactions with optional nested transactions via SAVEPOINT.
public struct TransactionManager {
    private let pool: ConnectionPool

    public init(pool: ConnectionPool) {
        self.pool = pool
    }

    /// Runs the given operation within a database transaction.
    ///
    /// - Parameters:
    ///   - nested: If true, uses a SAVEPOINT for nested transactions.
    ///   - operation: A closure that receives a `PostgresConnection` and returns a result.
    /// - Returns: The result of the operation.
    @discardableResult
    public func transaction<T>(
        nested: Bool = false,
        operation: (PostgresConnection) async throws -> T
    ) async throws -> T {
        // 1. Borrow a connection
        let conn = try await pool.connection()

        do {
            // 2. Begin transaction or savepoint
            if nested {
                _ = try await conn.simpleQuery("SAVEPOINT sp;").get()
            } else {
                _ = try await conn.simpleQuery("BEGIN;").get()
            }

            // 3. Execute user operation
            let result = try await operation(conn)

            // 4. Commit or release savepoint
            if nested {
                _ = try await conn.simpleQuery("RELEASE SAVEPOINT sp;").get()
            } else {
                _ = try await conn.simpleQuery("COMMIT;").get()
            }

            // 5. Return connection to pool
            await pool.release(conn)
            return result
        } catch {
            // 6. Rollback on error
            if nested {
                _ = try? await conn.simpleQuery("ROLLBACK TO SAVEPOINT sp;").get()
            } else {
                _ = try? await conn.simpleQuery("ROLLBACK;").get()
            }
            await pool.release(conn)
            throw error
        }
    }
}
