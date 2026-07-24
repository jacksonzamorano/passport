public enum SourceOrigin: Sendable {
    case table(TableReference),
         cte(CTEIdentifier)
}
