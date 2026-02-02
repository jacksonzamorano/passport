import Foundation

public class DeleteQueryBuilder<T: Record, A: QueryArguments> {
    var parameters: DeleteQueryParameters = .init()
    var returnCount: ReturnCount = .many
    
    public func filter(_ cnd: QueryStringCondition<T, A>, joiner: String = "AND") {
        if var wh = self.parameters.wh {
            wh.append(.raw(" \(joiner) "))
            wh.append(contentsOf: cnd.components)
        } else {
            self.parameters.wh = cnd.components
        }
    }
}
