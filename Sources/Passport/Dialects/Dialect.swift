import Foundation

public protocol Dialect: Sendable {
    func typeFor(function fn: QueryFunction) throws(DialectError) -> DeclaredType
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
         dataTypeNotSupported,
         functionArgumentsNotValid,
         keywordViolated
    
    var codeString: String {
        "D\(String(format: "%04d", self.rawValue))"
    }
    
    var description: String {
        switch self {
        case .conditionNotSupported: "This dialect does not support this condition."
        case .joinKindNotSupported: "This dialect does not support this kind of join."
        case .dataTypeNotSupported: "This dialect does not support this data type. "
        case .functionArgumentsNotValid: "This function doesn't return a valid type with these parameters."
        case .keywordViolated: "This is a reserved keyword in this dialect and may not be used."
        }
    }
}

public struct DialectError: Error {
    let code: DialectErrorCode
    let context: String
}
