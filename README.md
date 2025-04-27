[![CI](https://github.com/thecoderatekid/SwiftPostgresDB/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/SwiftPostgresDB/actions)
[![Swift 5.9+](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-macOS%2012%2B%20%7C%20Linux-blue.svg)](https://swift.org/platform-support)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

# SwiftPostgresDB

A lightweight, performant, and easy-to-use PostgreSQL integration for Swift 5.9+ applications. It provides connection pooling, query execution, an ORM-like layer, transaction management, and robust error handling.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [ORM Example](#orm-example)
- [Configuration](#configuration)
  - [Environment & `.env`](#environment--env)
  - [JSON/YAML](#jsonyaml)
- [GitHub Actions](#github-actions)
- [License](#license)

---

## Features

- **Connection Management**
  - Async connection pooling
  - Configurable via environment variables, `.env` files, or JSON/YAML

- **Query Execution**
  - Raw SQL & prepared statements
  - Sync & Async APIs with Swift Concurrency (async/await)

- **ORM-like Abstraction**
  - Map `Codable` Swift types to PostgreSQL tables
  - Automatic CRUD operations

- **Transaction Management**
  - Begin, Commit, Rollback
  - Nested transactions via SAVEPOINT

- **Data Type Handling**
  - UUID, JSON/JSONB, arrays, timestamps → Swift types
  - Convenience initializers for `PostgresData`

- **Error Handling**
  - Clear, descriptive errors (`PostgresError`)

- **Security**
  - Always uses prepared statements
  - Prevents SQL injection

## Requirements

- Swift 5.9+
- macOS 12+ (Linux supported)
- Swift Package Manager (SPM)

## Installation

In your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/yourusername/SwiftPostgresDB.git", from: "1.0.0")
]
```

And add `"SwiftPostgresDB"` to your target’s dependencies.

## Quick Start

```swift
import SwiftPostgresDB
import NIOCore

// 1. Load config (env/.env or JSON/YAML or defaults)
let config = try PostgresConfiguration.load(           // throws on file errors
    envFile: ".env",                                   // optional
    configFile: "dbconfig.yaml"                        // optional
)

// 2. Create EventLoopGroup
let group = MultiThreadedEventLoopGroup(numberOfThreads: 2)

// 3. Connection Pool
let pool = try await ConnectionPool(
    config: config,
    eventLoopGroup: group,
    maxConnections: 10
)

// 4. Query Executor
let executor = QueryExecutor(pool: pool)

// 5. Run a test query
let rows = try await executor.execute("SELECT now() AS ts;")
let ts: Date = rows[0].column("ts")!.timestamp!
print("Server time:", ts)
```

## ORM Example

```swift
import SwiftPostgresDB
import NIOCore

struct User: Model {
  static let tableName = "users"
  var id: UUID?
  var name: String
  var email: String
}

let repo = Repository<User>(executor: executor)

// Create
var u = User(id: nil, name: "Alice", email: "alice@example.com")
try await repo.create(&u)

// Read
let fetched = try await repo.find(id: u.id!)
print(fetched?.name) // "Alice"

// Update
var updated = fetched!
updated.email = "alice2@example.com"
try await repo.update(updated)

// Delete
try await repo.delete(id: updated.id!)
```

## Configuration

### Environment & `.env`

The package reads:

- `PGHOST` (default: localhost)
- `PGPORT` (default: 5432)
- `PGUSER` (default: postgres)
- `PGPASSWORD` (default: "")
- `PGDATABASE` (default: postgres)
- `PGTLS` (default: false)

You may also load a `.env` file:

```swift
let config = try PostgresConfiguration.load(envFile: ".env")
```

### JSON/YAML

Provide a `config.yaml` or `config.json`:

```yaml
host: db.example.com
port: 5432
username: admin
password: s3cr3t
database: mydb
tls: true
```

Load it with:

```swift
let config = try PostgresConfiguration.load(configFile: "config.yaml")
```

## GitHub Actions

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [ main, develop, 'feature/**' ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Swift
        uses: fwal/setup-swift@v1
        with:
          swift-version: '5.9'
      - name: Install Tools
        run: |
          brew install swiftformat swiftlint || true
      - name: Format Check
        run: swiftformat --lint Sources Tests
      - name: Lint
        run: swiftlint lint --strict
      - name: Build
        run: swift build --disable-sandbox
      - name: Test
        run: swift test --disable-sandbox
```

## License

MIT
