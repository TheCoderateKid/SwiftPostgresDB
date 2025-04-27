//
//  QueryExecutor.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//

import PostgresNIO

public struct QueryExecutor {
    private let pool: ConnectionPool

    public init(pool: ConnectionPool) {
        self.pool = pool
    }

    /// Executes a SQL query with parameters and returns an array of `PostgresRow`.
    public func execute(
        _ sql: String,
        _ parameters: [PostgresData] = []
    ) async throws -> [PostgresRow] {
        // 1. Borrow a connection
        let conn = try await pool.connection()

        // 2. Perform the query, ensuring release on both success and error
        let rows: [PostgresRow]
        do {
            rows = try await conn.query(sql, parameters).get().rows
        } catch {
            // if the query fails, release and rethrow
            await pool.release(conn)
            throw error
        }
        // 3. Release and return
        await pool.release(conn)
        return rows
    }

    /// Executes a simple SQL statement (no returned rows).
    public func executeStatement(_ sql: String) async throws {
        // 1. Borrow
        let conn = try await pool.connection()

        // 2. Execute, releasing on error or success
        do {
            _ = try await conn.simpleQuery(sql).get()
        } catch {
            await pool.release(conn)
            throw error
        }
        // 3. Release
        await pool.release(conn)
    }
}

