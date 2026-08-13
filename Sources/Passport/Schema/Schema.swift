import Foundation

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

public func Schema(
    dialect: Dialect,
    @SchemaBuilder schemaItems: () -> [SchemaItem]
) {
    let schema = SchemaRepresentation(
        dialect: dialect,
        schemaItems: schemaItems()
    )

    if !schema.validate() {
        exit(1)
    }

//    let flags = Set(CommandLine.arguments.dropFirst())
    let build: BuildResult
    do {
        build = try schema.build()
    } catch {
        print("\(error.errors.count) errors found when compliling:")
        for error in error.errors {
            print(error.description)
        }
        return
    }

    for adapter in schema.adapters {
        do {
            for query in build.queries {
                try adapter.build(query: query)
            }
            try adapter.finalize()
        } catch {
            if let error = error as? AdapterError {
                print(error.description(language: adapter.builder.name))
            } else {
                print("\(error.localizedDescription)")
            }
        }
    }
    
    for (idx, migration) in schema.migrations.enumerated() {
        do {
            var migrationSQL = [String]()
            for step in migration.steps {
                migrationSQL.append(try dialect.buildMigrationStep(step: step))
            }
            
            let migrationCode = migrationSQL.joined(separator: "\n\n")
            
            let rootURL = try migration.location.url()
            if !FileManager.default.fileExists(atPath: rootURL.path()) {
                try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
            }
            
            let url = try migration.location.url().appending(path: String(format: "%05d.sql", idx+1))
            try migrationCode.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            if let error = error as? DialectError {
                print(error.description)
            } else {
                print(error.localizedDescription)
            }
        }
    }
}
