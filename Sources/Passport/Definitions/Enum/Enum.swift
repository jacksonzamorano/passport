import Foundation

/// Protocol for enums that can be included in a Passport schema.
///
/// The `Enum` protocol allows Swift enums to be used in schemas and generated
/// as database enum types and language-specific enums in the target languages.
///
/// Instead of conforming to this protocol manually, use the `@Enum` macro which
/// automatically generates the required implementations.
///
/// ## Example
/// ```swift
/// @Enum
/// enum UserRole: String {
///     case admin
///     case user
///     case guest
/// }
/// ```
public protocol Enum: SchemaCompatible, Sendable, RawRepresentable {
    /// A mapping of enum case names to their raw values
    static var variants: [String: String] { get }

    /// The name of this enum type (used for database type name and code generation)
    static var name: String { get }
}

/// Macro for automatically conforming an enum to the Enum protocol.
///
/// The `@Enum` macro generates the required protocol conformances and static properties
/// needed to use a Swift enum in a Passport schema. It works with String-based enums.
///
/// The macro generates:
/// - `Enum` protocol conformance
/// - `SchemaCompatible` protocol conformance
/// - `variants` static property mapping case names to raw values
/// - `name` static property with the enum's type name
/// - `schemaEntity` static property for schema integration
///
/// ## Example
/// ```swift
/// @Enum
/// enum Status: String {
///     case pending
///     case active
///     case inactive
/// }
///
/// // Use in a schema:
/// Schema {
///     Status.self
///     User.self
/// }
/// ```
///
/// ## Requirements
/// - The enum must have a `String` raw value type
/// - All cases must have explicit or implicit raw values
@attached(extension, conformances: Enum, SchemaCompatible)
@attached(member, names:
            named(variants),
            named(name),
            named(schemaEntity)
)
public macro Enum() = #externalMacro(
    module: "PassportMacros",
    type: "EnumMacro"
)
