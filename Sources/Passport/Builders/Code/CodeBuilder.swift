import Foundation

/// Manages the state and files during a code generation session.
///
/// `CodeBuildSession` tracks all files being generated during a code generation run,
/// manages their lifecycle, and provides access to configuration settings.
public class CodeBuildSession {
    public var schemaName: String
    /// All files that have been created or accessed during this session
    public var files: [File] = []

    /// Configuration settings for this build session
    public let configuration: CodeBuilderConfiguration

    /// Creates a new code build session.
    ///
    /// - Parameter configuration: Configuration for output paths and settings
    public init(schemaName: String, configuration: CodeBuilderConfiguration = .init()) {
        self.schemaName = schemaName
        self.configuration = configuration
    }

    /// Retrieves or creates a file with the given name.
    ///
    /// If a file with the specified name already exists in the session, it is returned.
    /// Otherwise, a new file is created, added to the session, and returned.
    ///
    /// - Parameter named: The name of the file to retrieve or create
    /// - Returns: The existing or newly created file
    func file(named: String, withExtension ext: String, prefill: String? = nil) -> File {
        var targetName: String!
        switch configuration.fileStrategy {
        case .monolithic:
            targetName = "\(schemaName).\(ext)"
        case .perEntity:
            targetName = "\(named).\(ext)"
        }
        
        if let f = files.first(where: { $0.name == targetName }) {
            return f
        }
        let file = File(name: targetName, root: configuration.root)
        if let prefill {
            file.append(prefill)
        }
        files.append(file)
        return file
    }

    /// Prints a summary of all files in the session to the console.
    ///
    /// This is useful for debugging and inspecting generated code during development.
    public func dump() {
        for f in files {
            print("--- \(f.name) ---")
            print(f.contents)
            print("\n\n- Will import \(f.imports.joined(separator: ", "))")
        }
    }
}

public enum RecordGenerationStrategy {
    case asRecords, asModels, none
}

/// Configuration options for code generation.
///
/// This struct contains settings that control where generated code is written
/// and other build-time options.
public struct CodeBuilderConfiguration {
    /// The root directory where generated files will be written
    var root: URL
    
    var fileStrategy: FileStrategy
    
    var generateRecords: RecordGenerationStrategy
    var generateModels: Bool
    var generateRoutes: Bool
    
    /// Creates a new configuration.
    ///
    /// - Parameter root: The root directory for output files. If nil, uses the current working directory.
    public init(
        root: URL? = nil,
        fileStrategy: FileStrategy = .monolithic,
        generateRecords: RecordGenerationStrategy = .asModels,
        generateModels: Bool = true,
        generateRoutes: Bool = false
    ) {
        if let root {
            self.root = root
        } else {
            self.root = Process().currentDirectoryURL!
        }
        self.fileStrategy = fileStrategy
        self.generateRecords = generateRecords
        self.generateModels = generateModels
        self.generateRoutes = generateRoutes
    }
}

/// Orchestrates the code generation process for a specific language.
///
/// `CodeBuilder` coordinates generating code for models, records, and enums
/// using a language-specific implementation. It manages the build session,
/// delegates to the language implementation, and finalizes all output files.
class CodeBuilder {
    /// The language implementation to use for code generation
    var language: Language
    
    /// The current build session managing files and state
    var session: CodeBuildSession

    /// Creates a new code builder.
    ///
    /// - Parameters:
    ///   - language: The language implementation to use
    ///   - configuration: Build configuration (defaults to current directory)
    public init(schemaName: String, language: Language, configuration: CodeBuilderConfiguration = .init()) {
        self.language = language
        self.session = .init(
            schemaName: schemaName, configuration: configuration
        )
    }

    public func build(models: [any Model.Type], records: [any Record.Type], enms: [any Enum.Type], routes: [ResolvedRoute]) throws {
        for enm in enms {
            try language.build(enm: enm, session: session)
        }
        if session.configuration.generateModels {
            for model in models {
                try language.build(model: model, session: session)
            }
        }
        switch session.configuration.generateRecords {
        case .asRecords:
            for record in records {
                try language.build(record: record, session: session)
            }
        case .asModels:
            for record in records {
                try language.build(model: record, session: session)
            }
        case .none:
            break
        }
        if session.configuration.generateRoutes {
            try language.build(routes: routes, session: session)
        }
    }

    /// Finalizes all files by writing them to disk.
    ///
    /// This method should be called after all models, records, and enums have been built.
    /// It processes each file in the session, resolves imports using the language implementation,
    /// and writes the final content to disk.
    ///
    /// - Throws: File I/O errors if writing fails
    public func finalize() throws {
        for f in session.files {
            try f.finalize(usingLanguage: language)
        }
    }
}
