
fileprivate extension NamedQuery {
    func goName() -> String {
        return name.first!.uppercased() + name.dropFirst()
    }
}

fileprivate let goPrefil = """
        type queryable interface {
            Query(query string, args ...interface{}) (*sql.Rows, error)
        }
        
        """

public enum GoArrayTypeWrapper {
    case none, pgArray
    
    func build(_ str: String, inFile file: File) -> String {
        switch self {
        case .none:
            return str
        case .pgArray:
            file.depend("github.com/lib/pq")
            return "pq.Array(\(str))"
        }
    }
}

public final class GoConfiguration {
    public var packageName: String = "main"
    public var uuidProvider: String = "github.com/google/uuid"
    public var uuidClass: String = "uuid.UUID"
    public var arrayTypeWrapper: GoArrayTypeWrapper = .none
    
    public init() {}
    public init(config: (GoConfiguration) -> Void) {
        config(self)
    }
}

public class Go: Language {
    
    public static let omitEmpty: FieldTag = .custom("omitempty")

    var config: GoConfiguration
    var sqlBuilder: SQLBuilder
    
    public init(sqlBuilder: SQLBuilder, config: GoConfiguration = .init()) {
        self.sqlBuilder = sqlBuilder
        self.config = config
    }
    
    public func comment(for comment: String) -> String {
        return "// \(comment)"
    }
    
    public func resolveImports(imports: [String]) -> String {
        return "package \(config.packageName)\n" + imports
            .map { "import \"\($0)\"" }
            .joined(
            separator: "\n"
        )
    }
    
    public func convert(type: DataType, inFile file: File) throws -> String {
        switch type {
        case .array(let inner):
            let inner = try self.convert(type: inner, inFile: file)
            return "[]" + inner
        case .optional(let inner):
            let inner = try self.convert(type: inner, inFile: file)
            return "*" + inner
        case .bool:
            return "bool"
        case .bytes:
            return "[]byte"
        case .double:
            return "float64"
        case .int32:
            return "int32"
        case .int64:
            return "int64"
        case .model(let model):
            return model.name
        case .datetime:
            file.depend("time")
            return "time.Time"
        case .uuid:
            file.depend(config.uuidProvider)
            return config.uuidClass
        case .string:
            return "string"
        case .value(let model):
            return model.name
        }
    }

    public func build(enm: any Enum.Type, session: CodeBuildSession) throws {
        let file = session.file(named: enm.name, withExtension: "go", prefill: goPrefil)
        
        let variants = enm.variants.map {
            "\(enm.name)\($0.key.snakeToPascalCase()) \(enm.name) = \"\($0.value)\""
        }.joined(separator: "\n\t")
        
        file.append("""
            type \(enm.name) string
            
            const (
                \(variants)
            )\n\n
            """)
    }
    public func build(model: any Model.Type, session: CodeBuildSession) throws {
        let file = session.file(
            named: model.name,
            withExtension: "go",
            prefill: goPrefil
        )
        let fields = try model.fields.map {
            let extraJsonTags = $0.field.tagged(with: Self.omitEmpty) ? ",omitempty" : ""
            let type = try convert(
                type: $0.field.description.dataType,
                inFile: file
            )
            return "\($0.name.snakeToPascalCase()) \(type) `json:\"\($0.name)\(extraJsonTags)\"`"
        }
        
        file.append("""
            type \(model.name) struct {
                \(fields.joined(separator: "\n\t"))
            }\n\n
            """)
        
    }
    public func build(record: any Record.Type, session: CodeBuildSession) throws {
        let file = session.file(
            named: record.name,
            withExtension: "go",
            prefill: goPrefil
        )
        try build(model: record, session: session)
        
        file.append("""
            func Scan\(record.name)(rows *sql.Rows, record *\(record.name)) error {
                return rows.Scan(\(record.fields.map { "&record.\($0.name.snakeToPascalCase())" }.joined(separator: ", ") ))
            }\n\n
            """)
        
        for query in record.queries {
            var returnValue: String!
            var parseValue: String!
            let recordNameCased = record.name.snakeToPascalCase()
            switch query.query.returnCount {
            case .one:
                returnValue = "(*\(recordNameCased), error)"
                parseValue = """
                    if err != nil {
                        return nil, err
                    }
                    defer rows.Close()
                    if rows.Next() {
                        var record \(recordNameCased)
                        err := Scan\(recordNameCased)(rows, &record)
                        if err != nil {
                            return nil, err
                        }
                        return &record, nil
                    }
                    return nil, nil
                """
            case .many:
                returnValue = "([]\(recordNameCased), error)"
                parseValue = """
                    if err != nil {
                        return nil, err
                    }
                    defer rows.Close()
                    records := make([]\(recordNameCased), 0)
                    for rows.Next() {
                        var record \(recordNameCased)
                        err := Scan\(recordNameCased)(rows, &record)
                        if err != nil {
                            return nil, err
                        }
                        records = append(records, record)
                    }
                    return records, nil
                """
            case .none:
                returnValue = "error"
            }
            
            file.depend("database/sql")
            var args: [String] = ["db queryable"]
            args.append(contentsOf: try query.query.arguments.map {
                "\($0.name) \(try convert(type: $0.dataType, inFile: file))"
            })
            
            let sql = sqlBuilder.build(query: query.query, forRecord: record).replacingOccurrences(
                of: "\"",
                with: "\\\""
            )
            var queryArgs: [String] = ["\"\(sql)\""]
            queryArgs.append(contentsOf: query.query.arguments.map { arg in
                switch arg.dataType {
                case .array(_):
                    return self.config.arrayTypeWrapper.build(arg.name, inFile: file)
                default:
                    return arg.name
                }
            })
            
            file.append("""
                func \(query.goName())(\(args.joined(separator: ", "))) \(returnValue!) {
                    rows, err := db.Query(\(queryArgs.joined(separator: ", ")))
                \(parseValue!)
                }\n\n
                """)
        }
    }
    public func build(routes: [ResolvedRoute], session: CodeBuildSession) throws {
        let file = session.file(named: "\(session.schemaName)API", withExtension: "go", prefill: goPrefil)

        let variants = routes.map {
            """
            var \(session.schemaName)Route\($0.route.name.snakeToPascalCase()) = \(session.schemaName)Route{
                Method: "\($0.route.method.rawValue)",
                Path: "\($0.url)",
            }
            
            """
        }.joined(separator: "\n")
        
        file.append("""
            type \(session.schemaName)Route struct {
                Method string
                Path string
            }
            
            \(variants)
            """)
    }
    
}
