//
//  Repository.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//

import Foundation
import PostgresNIO

/// Basic CRUD for any `Model`.
public struct Repository<T: Model> {
    private let executor: QueryExecutor

    public init(executor: QueryExecutor) {
        self.executor = executor
    }

    /// Inserts a new record and updates `model.id`.
    public func create(_ model: inout T) async throws {
        let data = try JSONEncoder().encode(model)
        let json = String(data: data, encoding: .utf8)!
        let sql = """
        INSERT INTO \(T.tableName) (id, data)
        VALUES ($1::uuid, $2::jsonb)
        RETURNING id, data;
        """

        // ensure an ID
        let id = model.id ?? UUID()

        // use our convenience initializers:
        let params: [PostgresData] = [
            PostgresData(binaryUUID: id),
            PostgresData(jsonString: json),
        ]

        let rows = try await executor.execute(sql, params)
        guard let first = rows.first else {
            throw PostgresError("Create returned no rows.")
        }

        // Use RandomAccessRow for O(1) lookup
        let rar = PostgresRandomAccessRow(first)
        guard
            let returnedID = rar[data: "id"].uuid,
            let dataText = rar[data: "data"].string,
            let d = dataText.data(using: .utf8)
        else {
            throw PostgresError("Create failed decoding.")
        }

        model.id = returnedID
        model = try JSONDecoder().decode(T.self, from: d)
    }

    /// Fetches a record by its UUID.
    public func find(id: UUID) async throws -> T? {
        // 1. Define SQL
        let sql = "SELECT data FROM \(T.tableName) WHERE id = $1;"

        // 2. Execute with our binary‐UUID parameter
        let rows = try await executor.execute(
            sql, [PostgresData(binaryUUID: id)]
        )

        // 3. Bail out if no rows
        guard let first = rows.first else {
            return nil
        }

        // 4. Wrap for random-access
        let rar = PostgresRandomAccessRow(first)

        // 5. Extract the JSON text from "data"
        guard
            let jsonString = rar[data: "data"].string,
            let jsonData = jsonString.data(using: .utf8)
        else {
            return nil
        }

        // 6. Decode into T and return
        return try JSONDecoder().decode(T.self, from: jsonData)
    }

    /// Updates an existing record.
    public func update(_ model: T) async throws {
        guard let id = model.id else {
            throw PostgresError("Missing id.")
        }
        let data = try JSONEncoder().encode(model)
        let json = String(data: data, encoding: .utf8)!

        let sql = """
        UPDATE \(T.tableName)
        SET data = $1::jsonb
        WHERE id = $2::uuid;
        """

        let params: [PostgresData] = [
            PostgresData(jsonString: json),
            PostgresData(binaryUUID: id),
        ]

        _ = try await executor.execute(sql, params)
    }

    /// Deletes a record by its UUID.
    public func delete(id: UUID) async throws {
        let sql = "DELETE FROM \(T.tableName) WHERE id = $1;"
        _ = try await executor.execute(sql, [PostgresData(binaryUUID: id)])
    }
}
