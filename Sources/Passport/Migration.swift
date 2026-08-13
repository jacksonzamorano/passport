import Foundation

public enum MigrationStep: Sendable {
    case createTable(CreateTableMigrationStep),
         createColumn(CreateColumnMigrationStep)
    
    var name: String {
        switch self {
        case .createTable(let table): "create-\(table.table.tableName)"
        case .createColumn(let column): "alter-\(column.table.tableName)-create-\(column.name)"
        }
    }
}

public protocol IntoMigrationStep {
    func intoMigrationStep() -> MigrationStep
}

public struct CreateTableMigrationStep: IntoMigrationStep, Sendable {
    public let table: any Table.Type
    public let columns: [ColumnSnapshot]
    
    public struct ColumnSnapshot: Sendable {
        public let name: String
        public let column: Column
    }
    
    public init<T: Table>(_ table: T.Type) {
        self.table = T.self
        self.columns = T.Key.allCases.map { ColumnSnapshot(name: $0.rawValue, column: T.column($0)) }
    }
    
    public func intoMigrationStep() -> MigrationStep {
        return .createTable(self)
    }
}

public struct CreateColumnMigrationStep: IntoMigrationStep, Sendable {
    public let table: any Table.Type
    public let column: Column
    public let name: String
    
    public init<T: Table>(_ table: T.Type, column: T.Key) {
        self.table = T.self
        self.column = T.column(column)
        self.name = column.rawValue
    }
    
    public func intoMigrationStep() -> MigrationStep {
        return .createColumn(self)
    }
}

public struct Migration: Sendable, IntoSchemaItem {
    let location: FileLocation
    let steps: [MigrationStep]
    
    public init(location: FileLocation, @MigrationStepBuilder _ builder: () -> [MigrationStep]) {
        self.location = location
        self.steps = builder()
    }
    
    public func toSchemaItem() -> SchemaItem {
        .migration(self)
    }
}

@resultBuilder
public enum MigrationStepBuilder {
    public static func buildBlock(_ components: IntoMigrationStep...) -> [MigrationStep] {
        return components.map{ $0.intoMigrationStep() }
    }
}
