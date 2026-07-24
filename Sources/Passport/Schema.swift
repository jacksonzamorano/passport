import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

private class SchemaRepresentation {
    var dialect: Dialect
    var schemaItems: [SchemaItem]
    
    init(dialect: Dialect, schemaItems: [SchemaItem]) {
        self.dialect = dialect
        self.schemaItems = schemaItems
    }
    
    func dialectMapQueries(_ perform: (Query) throws -> Void) -> [DialectError] {
        var errors: [DialectError] = []
        
        for schemaItem in schemaItems {
            switch schemaItem {
            case .query(let query):
                do {
                    try perform(query)
                } catch {
                    if let error = error as? DialectError {
                        errors.append(error)
                    }
                }
            default: break
            }
        }
        
        return errors
    }
    
    func dialectMapMigrations(_ perform: (Migration) throws -> Void) -> [DialectError] {
        var errors: [DialectError] = []
        
        for schemaItem in schemaItems {
            switch schemaItem {
            case .migration(let migration):
                do {
                    try perform(migration)
                } catch {
                    if let error = error as? DialectError {
                        errors.append(error)
                    }
                }
            default: break
            }
        }
        
        return errors
    }
}

public func Schema(dialect: Dialect, @SchemaBuilder schemaItems: () -> [SchemaItem]) {
    let schemaTimeStart = Date()
    let schema = SchemaRepresentation(dialect: dialect, schemaItems: schemaItems())
    
    var errorsFound = false
    
    for item in schema.schemaItems {
        switch item {
        case .query(let query):
            do {
                try query.base.validate()
            } catch {
                print("[\(error.codeString)] (\(query.base.identity.queryName)): \(error.description)")
                errorsFound = true
            }
        default: break
        }
    }
    
    if errorsFound {
        exit(1)
    }
    let schemaSecondsTaken = -schemaTimeStart.timeIntervalSinceNow
    print(String(format: "Validated schema in %.2f seconds.", schemaSecondsTaken))
    
    let flags = Set(CommandLine.arguments.dropFirst())
    if flags.contains("--statements") {
        let opStart = Date()
        var errors = schema.dialectMapQueries { query in
            let code = try schema.dialect.buildQuery(query: query, context: .init())
            print("[\(query.base.identity.queryName)] \(code)")
        }
        errors.append(contentsOf: schema.dialectMapMigrations{ migration in
            for step in migration.steps {
                let code = try schema.dialect.buildMigrationStep(step: step)
                print("[Migration] \(code)")
            }
        })
        
        if !errors.isEmpty {
            print("\(errors.count) errors found when compliling:")
            for error in errors {
                print(error.string)
            }
        }
        let opEnd = -opStart.timeIntervalSinceNow
        print(String(format: "Built database code in %.2f seconds.", opEnd))
    }
}


public enum SchemaItem {
    case table(any Table),
         query(Query),
         migration(Migration)
}
public protocol IntoSchemaItem {
    func toSchemaItem() -> SchemaItem
}

@resultBuilder
public enum SchemaBuilder {
    public static func buildBlock(_ components: any IntoSchemaItem...) -> [SchemaItem] {
        return components.map({ $0.toSchemaItem() })
    }
}
