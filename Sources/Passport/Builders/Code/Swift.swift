import Foundation

public enum TargetedPlatform: Equatable {
    case bits32, bits64
}



public class Swift: Language {
    
    let fileStrategy: FileStrategy
    let targetedPlatform: TargetedPlatform?
    let standardizePropertyNames: Bool
    
    public init(
        fileStrategy: FileStrategy = .monolithic,
        targetedPlatform: TargetedPlatform? = nil,
        standardizePropertyNames: Bool = false
    ) {
        self.fileStrategy = fileStrategy
        self.targetedPlatform = targetedPlatform
        self.standardizePropertyNames = standardizePropertyNames
    }
    
    private func convertPropertyName(_ name: String) -> String {
        if standardizePropertyNames {
            return name.snakeToCamelCase()
        }
        return name
    }
    
    public func resolveImports(imports: [String]) -> String {
        return imports.map({ "import \($0)" }).joined(separator: "\n")
    }
    public func comment(for comment: String) -> String {
        return "// \(comment)"
    }
    public func convert(type: DataType, inFile file: File) throws -> String {
        switch type {
        case .array(let elementType):
            return "[\(try convert(type: elementType, inFile: file))]"
        case .model(let type):
            return type.name
        case .bool:
            return "Bool"
        case .bytes:
            return "Data"
        case .datetime:
            file.depend("Foundation")
            return "Date"
        case .double:
            return "Double"
        case .int32:
            if targetedPlatform == .bits32 {
                return "Int"
            }
            return "Int32"
        case .int64:
            if targetedPlatform == .bits64 {
                return "Int"
            }
            return "Int64"
        case .optional(let type):
            return "\(try convert(type: type, inFile: file))?"
        case .string:
            return "String"
        case .uuid:
            file.depend("Foundation")
            return "UUID"
        case .value(let model):
            return model.name
        }
    }
    public func build(enm: any Enum.Type, session: CodeBuildSession) throws {
        let file = session.file(named: enm.name, withExtension: "swift")
        
        let variants = enm.variants.map {
            "case \($0.key) = \"\($0.value)\""
        }.joined(separator: "\n\t")
        
        file.append("""
            public enum \(enm.name): String, Codable, Sendable {
            \t\(variants)
            }
            
            """)
    }
    public func build(model: any Model.Type, session: CodeBuildSession) throws {
        let file = session.file(named: model.name, withExtension: "swift")
        
        var typeMap: [String:String] = [:]
        var displayNames: [String:String] = [:]
        for field in model.fields {
            typeMap[field.name] = try self
                .convert(type: field.field.description.dataType, inFile: file)
            displayNames[field.name] = convertPropertyName(field.name)
        }
        
        let fields = model.fields.map {
            "let \(displayNames[$0.name]!): \(typeMap[$0.name]!)"
        }
        
        let initalizerArgs = model.fields.map {
            "\(displayNames[$0.name]!): \(typeMap[$0.name]!)"
        }
        let initalizerBody = model.fields.map {
            "self.\(displayNames[$0.name]!) = \(displayNames[$0.name]!)"
        }
        
        file.append("""
            public struct \(model.name): Codable, Sendable {
            \t\(fields.joined(separator: "\n\t"))
            
                public init(\(initalizerArgs.joined(separator: ", "))) {
                    \(initalizerBody.joined(separator: "\n\t\t"))
                }
            }
            
            """)
    }
    public func build(record: any Record.Type, session: CodeBuildSession) throws {
        throw LanguageError.recordsNotSupported
    }
    
    public func build(routes: [ResolvedRoute], session: CodeBuildSession) throws {
        let file = session.file(
            named: "\(session.schemaName)API",
            withExtension: "swift"
        )
        file.append("""
        public struct ApiRoute: Sendable {
            let method: String
            let path: String
        }
        
        public enum ApiRoutes: Sendable {
        \(routes.map {
        """
            case \($0.route.name)
        """
        }.joined(separator: "\n"))
        
            public var route: ApiRoute {
                switch self {
        \(routes.map { route in
        """
                    case .\(route.route.name): return ApiRoute(method: "\(route.route.method.rawValue)", path: "\(route.url)")
        """
        }.joined(separator: "\n"))
                }
            }
        }
        
        """)
    }
}
