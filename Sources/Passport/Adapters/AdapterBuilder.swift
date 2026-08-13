import Foundation

public protocol AdapterBuilder {
    var name: String { get }
    
    func resolveImport(importName: String) -> String
    func buildQuery(query: BuiltQuery, inContext context: AdapterContext) throws(AdapterError)
}

public enum FileLocation: Sendable {
    case gitRoot(appending: [String]),
         currentDirectory(appending: [String])

    func url() throws -> URL {
        switch self {
        case .gitRoot(let appending):
            var path = URL.currentDirectory()
            while path.lastPathComponent != "" {
                let components = try FileManager.default.contentsOfDirectory(
                    atPath: path.path()
                )
                if components.contains(".git") {
                    for a in appending {
                        path = path.appending(component: a)
                    }
                    return path
                }
                path.deleteLastPathComponent()
            }
            return path
        case .currentDirectory(let appending):
            var path = URL.currentDirectory()
            for a in appending {
                path = path.appending(component: a)
            }
            return path
        }
    }
}

public struct Adapter: IntoSchemaItem {
    let builder: AdapterBuilder
    let context: AdapterContext
    
    public init(_ builder: AdapterBuilder, generateInto location: FileLocation) {
        self.builder = builder
        self.context = .init(projectPath: try! location.url())
    }
    
    public func toSchemaItem() -> SchemaItem {
        .adapter(self)
    }
    
    func build(query: BuiltQuery) throws(AdapterError) {
        try builder.buildQuery(query: query, inContext: context)
    }
    
    func finalize() throws {
        for file in context.files {
            try file.writeFile(withAdapter: builder)
        }
    }
}

public enum AdapterErrorCode: Int, Sendable {
    case typeNotSupported,
         
         writeFailed
    
    var codeString: String {
        String(format: "V%04d", rawValue+1)
    }
    
    var description: String {
        switch self {
        case .typeNotSupported: "This adapter doesn't support this type"
        case .writeFailed: "The file could not be written."
        }
    }
}

public struct AdapterError: Error {
    public let code: AdapterErrorCode
    public let location: String

    public init(code: AdapterErrorCode, location: String) {
        self.code = code
        self.location = location
    }
    
    public func description(language: String) -> String {
        "[A\(code.codeString)] (\(language)) \(code.description): \(location)"
    }
}
