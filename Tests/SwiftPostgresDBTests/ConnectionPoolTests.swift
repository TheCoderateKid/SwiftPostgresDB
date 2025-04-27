//
//  ConnectionPoolTests.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//

import NIO
import NIOPosix
import PostgresNIO
@testable import SwiftPostgresDB
import XCTest

final class ConnectionPoolTests: XCTestCase {
    func testOpenClose() async throws {
        let cfg = PostgresConfiguration()
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let pool = ConnectionPool(config: cfg, eventLoopGroup: group, maxConnections: 2)
        let conn = try await pool.connection()
        defer { Task { await pool.release(conn) } }
        let rows = try await conn.simpleQuery("SELECT 1;").get()
        XCTAssertFalse(rows.isEmpty)
        try await pool.shutdown()
        try await group.shutdownGracefully()
    }
}
