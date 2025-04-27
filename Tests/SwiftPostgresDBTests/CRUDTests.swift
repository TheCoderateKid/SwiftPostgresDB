//
//  CRUDTests.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//

import NIO
import NIOCore
@testable import SwiftPostgresDB
import XCTest

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

        let fetchedUser = try await repo.find(id: user.id!)
        XCTAssertEqual(fetchedUser?.name, "Bob")

        var updatedUser = fetchedUser!
        updatedUser.email = "bob2@example.com"
        try await repo.update(updatedUser)

        let fetchedUpdatedUser = try await repo.find(id: updatedUser.id!)
        XCTAssertEqual(fetchedUpdatedUser?.email, "bob2@example.com")

        try await repo.delete(id: updatedUser.id!)
        let deletedUser = try await repo.find(id: updatedUser.id!)
        XCTAssertNil(deletedUser)

        try await exec.executeStatement("DROP TABLE test_users;")
        try await pool.shutdown()
        try await group.shutdownGracefully()
    }
}

struct TestUser: Model {
    static let tableName = "test_users"
    var id: UUID?
    var name: String
    var email: String
}
