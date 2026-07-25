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

    for query in build.queries {
        print(query.queryName)
        for returnColumn in query.returnColumns {
            print("\t\(returnColumn.name) -> \(returnColumn.fullDataType.dataType) (\(returnColumn.fullDataType.optional ? "Optional" : "Required"))")
        }
        print("\n\tQuery: \(query.query)\n---\n")
    }
}
