//
//  PostgresData+Convenience.swift
//  SwiftPostgresDB
//
//  Created by CL on 4/26/25.
//

import Foundation
import NIOCore
import PostgresNIO

public extension PostgresData {
    /// Create a JSONB parameter from a raw JSON string.
    init(jsonString: String) {
        // JSONB binary format = 1-byte version + UTF-8 JSON text
        var buf = ByteBufferAllocator().buffer(capacity: jsonString.utf8.count + 1)
        buf.writeInteger(UInt8(1)) // version byte
        buf.writeString(jsonString) // JSON payload

        self.init(
            type: .jsonb,
            typeModifier: nil,
            formatCode: .binary,
            value: buf
        )
    }

    /// Create a UUID parameter in **binary** format (16 bytes).
    init(binaryUUID uuid: UUID) {
        // Allocate exactly 16 bytes
        var buf = ByteBufferAllocator().buffer(capacity: 16)
        // Write the raw bytes of the UUID struct
        withUnsafeBytes(of: uuid.uuid) { rawPtr in
            let bytes = rawPtr.bindMemory(to: UInt8.self)
            buf.writeBytes(bytes)
        }

        self.init(
            type: .uuid,
            typeModifier: nil,
            formatCode: .binary,
            value: buf
        )
    }

    /// Create a UUID parameter in **text** format (e.g. "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX").
    init(textUUID uuid: UUID) {
        let uuidText = uuid.uuidString
        var buf = ByteBufferAllocator().buffer(capacity: uuidText.utf8.count)
        buf.writeString(uuidText)

        self.init(
            type: .uuid,
            typeModifier: nil,
            formatCode: .text,
            value: buf
        )
    }

    /// Create a text-array parameter from an array of Strings.
    /// Produces a literal like `{"one","two","three"}`.
    init(textArray: [String]) {
        let literal = "{\(textArray.map { "\"\($0)\"" }.joined(separator: ","))}"
        var buf = ByteBufferAllocator().buffer(capacity: literal.utf8.count)
        buf.writeString(literal)

        self.init(
            type: .textArray,
            typeModifier: nil,
            formatCode: .text,
            value: buf
        )
    }
}
