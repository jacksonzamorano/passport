import Foundation

public protocol Dialect: Sendable {
    func buildQuery(query: Query, context: RenderContext) throws(DialectError) -> String
    func buildMigrationStep(step: MigrationStep) throws(DialectError) -> String
}

public class RenderContext {
    var arguments: [Argument] = []
    var argumentCount: Int { arguments.count }
    public init() {}
}

public enum DialectErrorCode: Int, Sendable {
    case conditionNotSupported,
         joinKindNotSupported,
         dataTypeNotSupported
    
    var description: String {
        switch self {
        case .conditionNotSupported: "This dialect does not support this condition."
        case .joinKindNotSupported: "This dialect does not support this kind of join."
        case .dataTypeNotSupported: "This dialect does not support this data type. "
        }
    }
}

public struct DialectError: Error {
    let error: DialectErrorCode
    let entityName: String
    let context: String
    
    var string: String {
        "[D\(String(format: "%0", error.rawValue))] (\(entityName)): '\(context)' \(error.description)"
    }
}
