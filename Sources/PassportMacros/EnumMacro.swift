import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftSyntaxMacros
import SwiftCompilerPlugin

public struct EnumMacro: ExtensionMacro, MemberMacro {
    
    public static func expansion(
        of attribute: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        return [try! .init("""
        extension \(type): Enum { }
        extension \(type): SchemaCompatible { }
        """)]
        
    }
    
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(.init(node: declaration, message: MacroExpansionErrorMessage("The @Enum decorator can only be applied to enums.")))
            throw MacroExpansionErrorMessage("The @Enum decorator can only be applied to enums.")
        }
        
        let cases = enumDecl.memberBlock.members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .flatMap { $0.elements }
            .map {
                var setRawValue = $0.name.text
                if let explicitRawValue = $0.rawValue?.trimmedDescription {
                    setRawValue = explicitRawValue
                }
                return "\"\($0.name.text)\": \"\(setRawValue)\""
            }
            .joined(separator: ", ")
        
        let name = enumDecl.name.text
        let ext: DeclSyntax = """
        static let variants: [String: String] = [\(raw: cases)]
        static let name: String = "\(raw: name)"
        static let schemaEntity: SchemaEntity = SchemaEntity.enm(Self.self)
        """

        return [ext]
    }
}
