import Foundation

public indirect enum Condition: Sendable {
    case equals(ColumnReference, ColumnReference), null(ColumnReference), notNull(ColumnReference)
}
