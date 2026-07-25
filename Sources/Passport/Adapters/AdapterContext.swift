import Foundation

public class AdapterContext {
    var files: [AdapterFile] = []
    var projectPath: URL
    
    init(projectPath: URL) {
        self.projectPath = projectPath
    }
    
    public func file(
        path: String,
        initialContents: String? = nil,
        prefix: String? = nil,
        after: [String]? = nil
    ) -> AdapterFile {
        if !FileManager.default.fileExists(atPath: projectPath.path()) {
            try? FileManager.default.createDirectory(at: projectPath, withIntermediateDirectories: true)
        }
        
        if let existingFile = files.first(where: { $0.scopedPath == path }) {
            return existingFile
        }
        
        let file = AdapterFile(projectPath: projectPath.appending(path: path), scopedPath: path, prefix: prefix, after: after)
        files.append(file)
        if let initialContents {
            file.write(initialContents)
        }
        return file
    }
    
}

public class AdapterFile {
    enum GenerationError: Error, LocalizedError {
        case commandFailed(String), cannotWrite
        
        var errorDescription: String? {
            switch self {
            case .commandFailed(let e): "Could not run command '\(e)'"
            case .cannotWrite: "Cannot write to file."
            }
        }
    }
    
    private var importSet: Set<String> = Set()
    
    private let prefix: String?
    private let projectPath: URL
    let scopedPath: String
    private let after: [String]?
    
    private var fileContents: String = ""

    init(
        projectPath: URL,
        scopedPath: String,
        prefix: String? = nil,
        after: [String]? = nil
    ) {
        self.projectPath = projectPath
        self.scopedPath = scopedPath
        self.prefix = prefix
        self.after = after
    }
    
    public func write(_ contents: String) {
        self.fileContents.append(contents)
        self.fileContents.append("\n")
    }
    
    public func require(_ importString: String) {
        self.importSet.insert(importString)
    }
    
    internal func writeFile(withAdapter adapter: any AdapterBuilder) throws {
        let imports = importSet.sorted().map{ adapter.resolveImport(importName: $0) }
        var contents = String()
        if let prefix {
            contents.append("\(prefix)\n\n")
        }
        contents.append("""
            \(imports.joined(separator: "\n"))
            
            \(fileContents)
            """)
        try contents.write(to: projectPath, atomically: true, encoding: .utf8)
        
        if let after {
            let process = Process()
            let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/sh"
            
            process.currentDirectoryURL = projectPath.deletingLastPathComponent()
            process.executableURL = URL(filePath: shell)
            process.arguments = ["-c", after.joined(separator: " ")]
            
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                throw GenerationError.commandFailed(after.joined(separator: " "))
            }
        }
    }
}
