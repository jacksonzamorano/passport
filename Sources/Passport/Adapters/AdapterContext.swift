import Foundation

public class AdapterContext {
    private var files: [AdapterFile] = []
    private var projectPath: URL
    private var contextPath: URL
    
    init(projectPath: URL, contextPath: String) {
        self.projectPath = projectPath
        self.contextPath = projectPath.appending(path: contextPath)
    }
    
    public func file(path: String, initialContents: String? = nil) -> AdapterFile {
        if let existingFile = files.first(where: { $0.scopedPath == path }) {
            return existingFile
        }
        
        let file = AdapterFile(projectPath: contextPath.appending(path: path), scopedPath: path)
        files.append(file)
        if let initialContents {
            file.write(initialContents)
        }
        return file
    }
}

public class AdapterFile {
    private var imports: Set<String> = Set()
    
    private var projectPath: URL
    var scopedPath: String
    private var fileContents: String = ""
    
    init(projectPath: URL, scopedPath: String) {
        self.projectPath = projectPath
        self.scopedPath = scopedPath
    }
    
    public func write(_ contents: String) {
        self.fileContents.append(contents)
    }
    
    public func require(_ importString: String) {
        self.imports.insert(importString)
    }
}
