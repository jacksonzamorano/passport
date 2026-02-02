/// Protocol for implementing language-specific code generation.
///
/// The `Language` protocol defines the interface that all code generators must implement
/// to support generating code in a specific programming language (e.g., Go, TypeScript, Swift).
///
/// Each language implementation handles:
/// - Converting Passport data types to language-specific types
/// - Generating appropriate comment syntax
/// - Managing language-specific imports
/// - Building models, records, and enums in the target language
///
/// ## Example Implementation
/// ```swift
/// struct MyLanguage: Language {
///     func comment(for comment: String) -> String {
///         return "// \(comment)"
///     }
///
///     func convert(type: DataType, inFile file: File) throws -> String {
///         // Convert DataType to language-specific type string
///     }
///
///     // ... implement other required methods
/// }
/// ```
public protocol Language {
    /// Converts a string into a language-specific comment.
    ///
    /// - Parameter comment: The comment text to format
    /// - Returns: The formatted comment in the target language's syntax
    func comment(for comment: String) -> String

    /// Converts a Passport DataType to a language-specific type string.
    ///
    /// - Parameters:
    ///   - type: The Passport data type to convert
    ///   - file: The file context where this type will be used (for tracking imports)
    /// - Returns: The type representation in the target language
    /// - Throws: `LanguageError` if the type cannot be converted
    func convert(type: DataType, inFile file: File) throws -> String

    /// Generates the import/include statements for the target language.
    ///
    /// - Parameter imports: Array of import identifiers needed by the generated code
    /// - Returns: Formatted import statements for the target language
    func resolveImports(imports: [String]) -> String

    /// Generates code for a Model in the target language.
    ///
    /// - Parameters:
    ///   - model: The Model type to generate code for
    ///   - session: The code build session for managing files and configuration
    /// - Throws: `LanguageError` if code generation fails
    func build(model: any Model.Type, session: CodeBuildSession) throws

    /// Generates code for a Record in the target language.
    ///
    /// Records typically include database-related functionality beyond basic models.
    ///
    /// - Parameters:
    ///   - record: The Record type to generate code for
    ///   - session: The code build session for managing files and configuration
    /// - Throws: `LanguageError` if code generation fails
    func build(record: any Record.Type, session: CodeBuildSession) throws

    /// Generates code for an Enum in the target language.
    ///
    /// - Parameters:
    ///   - enm: The Enum type to generate code for
    ///   - session: The code build session for managing files and configuration
    /// - Throws: `LanguageError` if code generation fails
    func build(enm: any Enum.Type, session: CodeBuildSession) throws
    
    func build(routes: [ResolvedRoute], session: CodeBuildSession) throws
}
