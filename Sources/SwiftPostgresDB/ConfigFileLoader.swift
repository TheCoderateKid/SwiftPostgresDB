//
//  ConfigFileLoader.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//


import Foundation
import Yams

/// Decodes JSON or YAML config into `PostgresConfiguration`.
public struct ConfigFileLoader {
    public static func load(from path: String) throws -> PostgresConfiguration {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let ext = url.pathExtension.lowercased()
        let decoder = JSONDecoder()
        let cfg: ConfigFile

        if ext == "json" {
            cfg = try decoder.decode(ConfigFile.self, from: data)
        } else if ext == "yaml" || ext == "yml" {
            let yaml = String(data: data, encoding: .utf8)!
            let dict = try Yams.load(yaml: yaml) as? [String: Any] ?? [:]
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            cfg = try decoder.decode(ConfigFile.self, from: jsonData)
        } else {
            throw PostgresError("Unsupported config file extension: \(ext)")
        }

        return PostgresConfiguration(
            host: cfg.host,
            port: cfg.port,
            username: cfg.username,
            password: cfg.password,
            database: cfg.database,
            tls: cfg.tls
        )
    }
}

private struct ConfigFile: Codable {
    let host: String?
    let port: Int?
    let username: String?
    let password: String?
    let database: String?
    let tls: Bool?
}
