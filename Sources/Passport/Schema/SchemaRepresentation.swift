import Foundation

internal class SchemaRepresentation {
    var dialect: Dialect
    var schemaItems: [SchemaItem]
    
    init(dialect: Dialect, schemaItems: [SchemaItem]) {
        self.dialect = dialect
        self.schemaItems = schemaItems
    }
    
    func build() throws(CompilationErrors) -> BuildResult {
        let opStart = Date()
        
        var errors = CompilationErrors()
        var results = BuildResult()
        do {
            results.queries = try buildQueries()
        } catch {
            errors.join(error)
        }
        do {
            results.migrations = try buildMigrations()
        } catch {
            errors.join(error)
        }
        let opEnd = -opStart.timeIntervalSinceNow
        print(String(format: "Built database code in %.2f seconds.", opEnd))
        return results
    }
    
    private func buildQueries() throws(CompilationErrors) -> [BuiltQuery] {
        var errors = CompilationErrors()
        var builtQueries: [BuiltQuery] = []
        
        for schemaItem in schemaItems {
            switch schemaItem {
            case .query(let query):
                do {
                    let context = RenderContext()
                    let queryString = try dialect.buildQuery(query: query, context: context)
                    builtQueries.append(.init(query: queryString, arguments: context.arguments))
                } catch {
                    errors.errors.append(
                        .init(error: error, location: query.base.identity.queryName)
                    )
                }
            default: break
            }
        }
        
        if errors.hasErrors {
            throw errors
        }
        
        return builtQueries
    }
    
    private func buildMigrations() throws(CompilationErrors) -> [BuiltMigration] {
        var migrations: [BuiltMigration] = []
        var errors = CompilationErrors()
        
        var migrationCount = 0
        for schemaItem in schemaItems {
            switch schemaItem {
            case .migration(let migration):
                migrationCount += 1
                do {
                    var builtMigration = BuiltMigration(steps: [])
                    for step in migration.steps {
                        let result = try dialect.buildMigrationStep(step: step)
                        builtMigration.steps.append(.init(name: step.name, query: result))
                    }
                    migrations.append(builtMigration)
                } catch {
                    errors.add(error, location: "Migration #\(migrationCount)")
                }
            default: break
            }
        }
        
        if errors.hasErrors {
            throw errors
        }
        
        return migrations
    }
}
