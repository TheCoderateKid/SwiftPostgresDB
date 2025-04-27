//
//  ConnectionPool.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//

import Logging
import NIOCore
import PostgresNIO

/// Asynchronous PostgreSQL connection pool.
public actor ConnectionPool {
    private let configuration: PostgresConnection.Configuration
    private let eventLoopGroup: EventLoopGroup
    private var available: [PostgresConnection] = []
    private var inUse: Set<ObjectIdentifier> = []
    private let maxConnections: Int

    public init(
        config: PostgresConfiguration,
        eventLoopGroup: EventLoopGroup,
        maxConnections: Int = 10
    ) {
        configuration = config.connection
        self.eventLoopGroup = eventLoopGroup
        self.maxConnections = maxConnections
    }

    /// Borrow a connection from the pool.
    public func connection() async throws -> PostgresConnection {
        if let conn = available.popLast() {
            inUse.insert(ObjectIdentifier(conn))
            return conn
        }

        if inUse.count < maxConnections {
            // create a logger for Postgres
            let logger = Logger(label: "PostgresConnectionPool")

            // New signature: connect(on: EventLoop, configuration: , id:, logger:)
            let conn = try await PostgresConnection
                .connect(
                    on: eventLoopGroup.next(),
                    configuration: configuration,
                    id: 0, // any Int metadata—0 is fine
                    logger: logger
                )
                .get()

            inUse.insert(ObjectIdentifier(conn))
            return conn
        }

        // wait for release
        while true {
            if let conn = available.popLast() {
                inUse.insert(ObjectIdentifier(conn))
                return conn
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    /// Return a connection to the pool.
    public func release(_ conn: PostgresConnection) {
        let id = ObjectIdentifier(conn)
        guard inUse.remove(id) != nil else { return }
        available.append(conn)
    }

    /// Close all idle connections.
    public func shutdown() async throws {
        for conn in available {
            try await conn.close().get()
        }
        available.removeAll()
    }
}
