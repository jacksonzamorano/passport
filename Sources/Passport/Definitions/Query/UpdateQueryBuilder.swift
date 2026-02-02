import Foundation

public class UpdateQueryBuilder<T: Record, A: QueryArguments> {
    var parameters: UpdateQueryParameters = .init()

    
    public func set(_ cnd: QueryStringCondition<T, A>) {
        self.parameters.set = cnd.components
    }
    public func filter(_ cnd: QueryStringCondition<T, A>) {
        self.parameters.wh = cnd.components
    }
}
