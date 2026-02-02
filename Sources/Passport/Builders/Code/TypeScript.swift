import Foundation

public class TypeScript: Language {
    
    var buildIndex: Bool
    
    public init(buildIndex: Bool = false) {
        self.buildIndex = buildIndex
    }
    
    public func resolveImports(imports: [String]) -> String {
        return imports.map { "import \($0)" }.joined(separator: "\n")
    }
    public func comment(for comment: String) -> String {
        return "// \(comment)"
    }
    public func convert(type: DataType, inFile file: File) throws -> String {
        switch type {
        case .string, .uuid:
            return "string"
        case .int32, .int64, .double:
            return "number"
        case .bool:
            return "boolean"
        case .bytes:
            return "UInt8Array"
        case .datetime:
            return "Date"
        case .model(let model):
            file.depend("type {\(model.name)} from \"./\(model.name)\"")
            return model.name
        case .optional(let nested):
            return "\(try convert(type: nested, inFile: file)) | undefined"
        case .array(let nested):
            return "\(try convert(type: nested, inFile: file))[]"
        case .value(let model):
            file.depend("type {\(model.name)} from \"./\(model.name)\"")
            return model.name
        }
    }
    public func build(enm: any Enum.Type, session: CodeBuildSession) throws {
        let file = session.file(named: enm.name, withExtension: "ts")
        
        let variants = enm.variants.map { "\"\($0.value)\""}.joined(separator: " | ")
        file.append("""
            export type \(enm.name) = \(variants)
            
            """)
        addToIndex(name: enm.name, session: session)
    }
    public func build(model: any Model.Type, session: CodeBuildSession) throws {
        let file = session.file(named: model.name, withExtension: "ts")

        let fields = try model.fields.map {
            let type = try self.convert(
                type: $0.field.description.dataType,
                inFile: file
            )
            return "\($0.name): \(type)"
        }
        
        file.append("""
            export interface \(model.name) {
            \t\(fields.joined(separator: "\n\t"))
            }
            
            """)
        
        addToIndex(name: model.name, session: session)
    }
    
    private func addToIndex(name: String, file: String? = nil, session: CodeBuildSession) {
        if session.configuration.fileStrategy == .perEntity && self.buildIndex {
            if let file {
                session.file(named: "index", withExtension: "ts").append("export { \(name) } from './\(file)'\n")
            } else {
                session.file(named: "index", withExtension: "ts").append("export type { \(name) } from './\(name)'\n")
            }
        }
    }
    
    public func build(record: any Record.Type, session: CodeBuildSession) throws {
        throw LanguageError.recordsNotSupported
    }
    
    public func build(routes: [ResolvedRoute], session: CodeBuildSession) throws {
        let file = session.file(named: "api", withExtension: "ts")
        file.append("""
            interface Route {
                method: string
                path: string
            }
            export const Route = {
            \(routes.map {
                """
                    \($0.route.name): {
                        method: '\($0.route.method)',
                        path: '\($0.route.path)',
                    },
                """
            }.joined(separator: "\n"))
            }
            """)
        addToIndex(name: "Route", file: "api", session: session)
    }
}
