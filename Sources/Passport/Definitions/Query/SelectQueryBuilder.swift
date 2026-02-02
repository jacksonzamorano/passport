import Foundation

public class SelectQueryBuilder<T: Record, A: QueryArguments> {
    var parameters: SelectQueryParameters = .init()

    public func filter(_ cnd: QueryStringCondition<T, A>) {
        self.parameters.wh = cnd.components
    }
    
    public func group(_ keyPath: KeyPath<T, Field>) {
        self.parameters.group = T.field(forKeyPath: keyPath)?.name
    }
    
    public func one() {
        self.parameters.returnCount = .one
        self.parameters.limit = 1
    }
    public func many(_ limit: Int? = nil) {
        self.parameters.returnCount = .many
        self.parameters.limit = limit
    }
    public func none() {
        self.parameters.returnCount = .none
        self.parameters.limit = 1
    }
}
