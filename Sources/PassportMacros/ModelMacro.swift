import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftSyntaxMacros
import SwiftCompilerPlugin

struct EntityError: Error {
    var description: String
}

public struct ModelMacro: ExtensionMacro, MemberMacro {

    public static func expansion(
        of attribute: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        // We want: extension <Type>: TableCapable {}
        let ext: ExtensionDeclSyntax = try! .init("""
        extension \(type): Model {}
        extension \(type): SchemaCompatible {}
        """)

        return [ext]
    }

    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(.init(node: declaration, message: MacroExpansionErrorMessage("The @Model decorator can only be applied to structs.")))
            return []
        }
        return buildModel(
            syntax: structDecl,
            attribute: attribute,
            context: context,
            inRecordMode: false
        )
    }
}
