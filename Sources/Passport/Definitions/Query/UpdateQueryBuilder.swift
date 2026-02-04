import Foundation

public class UpdateQueryBuilder<T: Record, A: QueryArguments> {
    var parameters: UpdateQueryParameters = .init()

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

    
    public func set(_ cnd: QueryStringCondition<T, A>) {
        self.parameters.set = cnd.components
    }
    public func filter(_ cnd: QueryStringCondition<T, A>) {
        self.parameters.wh = cnd.components
    }

    public func one() {
        self.parameters.returnCount = .one
    }

    public func many() {
        self.parameters.returnCount = .many
    }
}
