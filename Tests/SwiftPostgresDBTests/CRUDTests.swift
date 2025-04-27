//
//  TestUser.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//


import NIO
import NIOCore
@testable import SwiftPostgresDB
import XCTest

struct TestUser: Model {
    static let tableName = "test_users"
    var id: UUID?
    var name: String
    var email: String
}

final class CRUDTests: XCTestCase {
    func testCRUD() async throws {
        let cfg = PostgresConfiguration()
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let pool = ConnectionPool(config: cfg, eventLoopGroup: group, maxConnections: 2)
        let exec = QueryExecutor(pool: pool)

        try await exec.executeStatement("""
        CREATE TABLE IF NOT EXISTS test_users (
          id UUID PRIMARY KEY,
          data JSONB NOT NULL
        );
        """)

        let repo = Repository<TestUser>(executor: exec)
        var user = TestUser(id: UUID(), name: "Bob", email: "bob@example.com")
        try await repo.create(&user)
        XCTAssertNotNil(user.id)

        let f1 = try await repo.find(id: user.id!)
        XCTAssertEqual(f1?.name, "Bob")

        var updated = f1!
        updated.email = "bob2@example.com"
        try await repo.update(updated)
        let f2 = try await repo.find(id: updated.id!)
        XCTAssertEqual(f2?.email, "bob2@example.com")

        try await repo.delete(id: updated.id!)
        let f3 = try await repo.find(id: updated.id!)
        XCTAssertNil(f3)

        try await exec.executeStatement("DROP TABLE test_users;")
        try await pool.shutdown()
        try await group.shutdownGracefully()
    }
}
