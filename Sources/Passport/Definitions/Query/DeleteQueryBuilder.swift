import Foundation

public class DeleteQueryBuilder<T: Record, A: QueryArguments> {
    var parameters: DeleteQueryParameters = .init()
    var returnCount: ReturnCount = .many

    public func cte<R: Record>(
        _ name: String,
        _ record: R.Type,
        _ build: @Sendable @escaping (SelectQueryBuilder<R, A>) -> Void
    ) -> CTEAlias<R> {
        let query = Query.select(record, A.self, build)
        self.parameters.ctes.removeAll { $0.name == name }
        self.parameters.ctes.append(QueryCTE(name: name, record: record, query: query))
        return CTEAlias<R>(name: name)
    }
    
    public func filter(_ cnd: QueryStringCondition<T, A>, joiner: String = "AND") {
        if var wh = self.parameters.wh {
            wh.append(.raw(" \(joiner) "))
            wh.append(contentsOf: cnd.components)
        } else {
            self.parameters.wh = cnd.components
        }
    }
}
