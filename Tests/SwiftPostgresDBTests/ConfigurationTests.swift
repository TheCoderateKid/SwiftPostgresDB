//
//  ConfigurationTests.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//

@testable import SwiftPostgresDB
import XCTest

final class ConfigurationTests: XCTestCase {
    func testDefault() {
        let config = PostgresConfiguration()
        XCTAssertEqual(
            config.host,
            ProcessInfo.processInfo.environment["PGHOST"] ?? "localhost"
        )
        XCTAssertEqual(
            config.port,
            Int(ProcessInfo.processInfo.environment["PGPORT"] ?? "") ?? 5432
        )
    }
}
