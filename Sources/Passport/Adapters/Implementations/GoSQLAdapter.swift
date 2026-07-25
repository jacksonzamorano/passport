import Foundation

public final class GoSQLAdapter: AdapterBuilder {
    
    public let name: String = "Go: db/sql"
    
    private let packageName: String
    
    public init(packageName: String = "main") {
        self.packageName = packageName
    }
    
    public func mapType(_ type: DeclaredType, inFile file: AdapterFile) throws(AdapterError) -> String {
        let typeString = switch type.dataType {
        case .string: "string"
        case .uuid:
            {
                file.require("github.com/google/uuid")
                return "uuid.UUID"
            }()
        case .integer:
            "int64"
        }
        
        if type.optional {
            return "*\(typeString)"
        }
        return typeString
    }
    
    public func resolveImport(importName: String) -> String {
        return "import \"\(importName)\""
    }
    
    public func buildQuery(query: BuiltQuery, inContext context: AdapterContext) throws(AdapterError) {
        let file = context.file(path: "model.go", prefix: "package \(packageName)")
        file.require("database/sql")
        
        var returnColumnString: [String] = []
        for column in query.returnColumns {
            returnColumnString.append("\(column.name) \(try mapType(column.fullDataType, inFile: file))")
        }
        
        let typeCode = """
            type \(query.queryReturnTypeName) struct {
                \(returnColumnString.joined(separator: "\n\t"))
            }
            """
        
        file.write(typeCode)
    }
}
