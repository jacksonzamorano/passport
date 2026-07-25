import Foundation

public class AdapterContext {
    var files: [AdapterFile] = []
    var projectPath: URL
    
    init(projectPath: URL) {
        self.projectPath = projectPath
    }
    
    public func file(path: String, initialContents: String? = nil, prefix: String? = nil) -> AdapterFile {
        if !FileManager.default.fileExists(atPath: projectPath.path()) {
            try? FileManager.default.createDirectory(at: projectPath, withIntermediateDirectories: true)
        }
        
        if let existingFile = files.first(where: { $0.scopedPath == path }) {
            return existingFile
        }
        
        let file = AdapterFile(projectPath: projectPath.appending(path: path), scopedPath: path, prefix: prefix)
        files.append(file)
        if let initialContents {
            file.write(initialContents)
        }
        return file
    }
    
}

public class AdapterFile {
    private var importSet: Set<String> = Set()
    
    private var prefix: String?
    private var projectPath: URL
    var scopedPath: String
    private var fileContents: String = ""
    
    init(projectPath: URL, scopedPath: String, prefix: String? = nil) {
        self.projectPath = projectPath
        self.scopedPath = scopedPath
        if let prefix {
            self.prefix = prefix
        }
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
    }
}
