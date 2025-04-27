//
//  PostgresConfiguration.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//

import Foundation
import NIOSSL
import PostgresNIO

/// Holds and loads PostgreSQL connection settings.
public struct PostgresConfiguration {
    public let host: String
    public let port: Int
    public let username: String
    public let password: String
    public let database: String
    public let tls: Bool

    /// Base initializer (env vars or defaults).
    public init(
        host: String? = nil,
        port: Int? = nil,
        username: String? = nil,
        password: String? = nil,
        database: String? = nil,
        tls: Bool? = nil
    ) {
        let env = ProcessInfo.processInfo.environment
        self.host = host ?? env["PGHOST"] ?? "localhost"
        self.port = port ?? Int(env["PGPORT"] ?? "") ?? 5432
        self.username = username ?? env["PGUSER"] ?? "postgres"
        self.password = password ?? env["PGPASSWORD"] ?? ""
        self.database = database ?? env["PGDATABASE"] ?? "postgres"
        self.tls = tls ?? (env["PGTLS"] == "true")
    }

    /// Advanced loader: optional .env + JSON/YAML.
    public static func load(
        envFile: String? = nil,
        configFile: String? = nil
    ) throws -> PostgresConfiguration {
        if let envFile {
            try EnvLoader.load(from: envFile)
        }
        if let configFile {
            return try ConfigFileLoader.load(from: configFile)
        }
        return PostgresConfiguration()
    }

    /// Convert to PostgresNIO configuration.
    var connection: PostgresConnection.Configuration {
        // Build the TLS mode
        let tlsMode: PostgresConnection.Configuration.TLS = {
            guard tls else { return .disable }
            let sslConfig = TLSConfiguration.makeClientConfiguration()
            let sslContext: NIOSSLContext
            do {
                sslContext = try NIOSSLContext(configuration: sslConfig)
            } catch {
                fatalError("Unable to create NIOSSLContext: \(error)")
            }
            return .require(sslContext)
        }()

        return PostgresConnection.Configuration(
            host: host,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: tlsMode
        )
    }
}
