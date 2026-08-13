import Foundation

public enum MigrationStep: Sendable {
    case createTable(CreateTable),
         createColumn(AddColumn),
         createIndex(IndexDefinition)
    
    var name: String {
        switch self {
        case .createTable(let table): "create-\(table.table.tableName)"
        case .createColumn(let column): "alter-\(column.table.tableName)-create-\(column.name)"
        case .createIndex(let index): "createindex-\(index.name)-\(index.tableName)"
        }
    }
}

public protocol IntoMigrationStep {
    func intoMigrationStep() -> MigrationStep
}

public struct CreateTable: IntoMigrationStep, Sendable {
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

public struct AddColumn: IntoMigrationStep, Sendable {
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

public struct CreateIndex: IntoMigrationStep, Sendable {
    public let index: IndexDefinition
    
    public init<I: Index>(_ index: I) {
        self.index = .init(configuration: index)
    }
    
    public func intoMigrationStep() -> MigrationStep {
        return .createIndex(index)
    }
}


public struct Migration: Sendable, IntoSchemaItem {
    let steps: [MigrationStep]
    
    public init(@MigrationStepBuilder _ builder: () -> [MigrationStep]) {
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
