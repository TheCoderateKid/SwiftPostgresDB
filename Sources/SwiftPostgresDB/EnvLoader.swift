//
//  EnvLoader.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//

import Foundation

/// Loads `.env` file entries into the process environment.
public enum EnvLoader {
    public static func load(from path: String = ".env") throws {
        let url = URL(fileURLWithPath: path)
        let content = try String(contentsOf: url, encoding: .utf8)
        for line in content.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#"),
                  let idx = trimmed.firstIndex(of: "=")
            else { continue }
            let key = String(trimmed[..<idx]).trimmingCharacters(in: .whitespaces)
            let val = String(trimmed[trimmed.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
            setenv(key, val, 1)
        }
    }
}
