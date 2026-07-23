import Foundation

public struct QueryIdentity: Sendable {
    let queryName: String
    var queryReturnTypeName: String
    
    public init(name: String) {
        self.queryName = name
        let nameFirstUppercased = "\(name.first!.uppercased())\(name.dropFirst(1))"
        self.queryReturnTypeName = "\(nameFirstUppercased)Result"
    }
}
