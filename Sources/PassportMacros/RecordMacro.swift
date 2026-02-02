import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftSyntaxMacros
import SwiftCompilerPlugin

struct TableError: Error {
    var description: String
}

struct NamedContent {
    var swiftName: String
    var internalName: String
    var definition: String
}


public struct RecordMacro: ExtensionMacro, MemberMacro {
    
    public static func expansion(
        of attribute: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        let ext: ExtensionDeclSyntax = try! .init("""
        extension \(type): Record {}
        extension \(type): SchemaCompatible {}
        """)
        
        return [ext]
    }
    
    private static func extractString(_ expr: ExprSyntax) -> String? {
        guard
            let stringLiteral = expr.as(StringLiteralExprSyntax.self),
            let firstSegment = stringLiteral.segments.first?.as(StringSegmentSyntax.self)
        else {
            return nil
        }

        return firstSegment.content.text
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
            inRecordMode: true
        )
    }
}
