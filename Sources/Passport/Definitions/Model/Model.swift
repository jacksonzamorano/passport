import Foundation

/// Qualifies a type to be generated. To make it database-aware, conform to ``Record``,
/// which requires conformance to this protocol as well.
public protocol Model: Sendable {
    /// An empty initializer is required for runtime reflection.
    init()
    /// A set of fields to build for this record, with a name attached to each.
    static var fields: [NamedField] { get }
    static func index(forKeyPath: KeyPath<Self, Field>) -> Int
    /// A helper function to convert a key path to it's ``Field``.
    static func field(forKeyPath: KeyPath<Self, Field>) -> NamedField?
    static var name: String { get }
}

@attached(extension, conformances: Model, SchemaCompatible)
@attached(member, names:
            named(name),
            named(schemaEntity),
            named(field),
            named(index),
            named(fields)
)
public macro Model() = #externalMacro(
    module: "PassportMacros",
    type: "ModelMacro"
)
