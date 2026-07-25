import Foundation

public final class GoSQLAdapter: AdapterBuilder {
    
    public let name: String = "Go: db/sql"
    
    private let packageName: String
    
    public init(packageName: String = "main") {
        self.packageName = packageName
    }
    
    public func goify(_ name: String) -> String {
        if let first = name.first, first.isLowercase {
            let rest = name.dropFirst()
            return "\(name.first!.uppercased())\(rest)"
        }
        
        return name
    }
    
    public func mapType(_ type: DeclaredType, inFile file: AdapterFile) throws(AdapterError) -> String {
        let typeString = switch type.dataType {
        case .string: "string"
        case .uuid:
            {
                file.require("github.com/google/uuid")
                return "uuid.UUID"
            }()
        case .integer32: "int32"
        case .integer64: "int64"
        case .blob: "[]byte"
        case .date, .dateWithTimezone:
            {
                file.require("time")
                return "time.Time"
            }()
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
        let file = context.file(
            path: "model.go",
            prefix: "package \(packageName)",
            after: ["gofmt", "-w", "."]
        )
        file.require("database/sql")
        
        var returnColumnString: [String] = []
        for column in query.returnColumns {
            returnColumnString.append("\(goify(column.name)) \(try mapType(column.fullDataType, inFile: file)) `json:\"\(column.name)\"`")
        }
        
        var argumentsString: [String] = []
        for argument in query.arguments {
            argumentsString.append("\(argument.name) \(try mapType(argument.dataType, inFile: file))")
        }
        
        let typeCode = """
            type \(goify(query.queryReturnTypeName)) struct {
                \(returnColumnString.joined(separator: "\n\t"))
            }
            
            func \(goify(query.queryName))(database *sql.DB, \(argumentsString.joined(separator: ", "))) ([]\(query.queryReturnTypeName), error) {
                var results []\(query.queryReturnTypeName)
                rows, err := database.Query("\(query.query)", \(query.arguments.map{ $0.name }.joined(separator: ", ")))
                if err != nil {
                    return results, err
                }
            
                defer rows.Close()
            
                for rows.Next() {
                    var result \(query.queryReturnTypeName)
                    err = rows.Scan(\(query.returnColumns.map{ "&result.\(goify($0.name))" }.joined(separator: ", ")))
                    if err != nil {
                        return results, err
                    }
                }
            
                if err := rows.Err(); err != nil {
                    return results, err
                }
            
                return results, nil
            }
            """
        
        file.write(typeCode)
    }
}
