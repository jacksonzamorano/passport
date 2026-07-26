import Foundation

internal class SchemaRepresentation {
    var dialect: Dialect
    var queries: [Query] = []
    var migrations: [Migration] = []
    var tables: [any Table] = []
    var adapters: [Adapter] = []
    
    init<D: Dialect>(dialect: D, schemaItems: [SchemaItem]) {
        self.dialect = dialect
        for schemaItem in schemaItems {
            switch schemaItem {
            case .query(let query): queries.append(query)
            case .migration(let migration): migrations.append(migration)
            case .table(let table): tables.append(table)
            case .adapter(let adapter): adapters.append(adapter)
            }
        }
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
        if errors.hasErrors {
            throw errors
        }
        return results
    }
    
    private func buildQueries() throws(CompilationErrors) -> [BuiltQuery] {
        var errors = CompilationErrors()
        var builtQueries: [BuiltQuery] = []
        
        for query in queries {
            do {
                let context = RenderContext()
                let queryString = try dialect.buildQuery(query: query, context: context)
                
                let builtQuery = BuiltQuery(
                    queryName: query.base.identity.queryName,
                    queryReturnTypeName: query.base.identity.queryReturnTypeName,
                    query: queryString,
                    arguments: context.arguments,
                    returnColumns: try BuiltQuery.getReturnShape(query: query, dialect: dialect)
                )
                
                builtQueries.append(builtQuery)
            } catch {
                errors.errors.append(
                    .init(error: error, location: query.base.identity.queryName)
                )
            }
        }
        
        if errors.hasErrors {
            throw errors
        }
        
        return builtQueries
    }
    
    private func buildMigrations() throws(CompilationErrors) -> [BuiltMigration] {
        var builtMigrations: [BuiltMigration] = []
        var errors = CompilationErrors()
        
        for (idx, migration) in migrations.enumerated() {
            do {
                var builtMigration = BuiltMigration(steps: [])
                for step in migration.steps {
                    let result = try dialect.buildMigrationStep(step: step)
                    builtMigration.steps.append(.init(name: step.name, query: result))
                }
                builtMigrations.append(builtMigration)
            } catch {
                errors.add(error, location: "Migration #\(idx+1)")
            }
        }
        
        if errors.hasErrors {
            throw errors
        }
        
        return builtMigrations
    }
}
