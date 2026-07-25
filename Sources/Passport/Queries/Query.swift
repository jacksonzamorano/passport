import Foundation

public enum Query: Sendable {
    case select(SelectQuery),
         insert(InsertQuery),
         update(UpdateQuery),
         delete(DeleteQuery)
    
    var base: BaseQueryProperties {
        switch self {
        case .select(let select): select
        case .insert(let insert): insert
        case .update(let update): update
        case .delete(let delete): delete
        }
    }
}
