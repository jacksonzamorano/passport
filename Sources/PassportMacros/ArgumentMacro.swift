import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftSyntaxMacros
import SwiftCompilerPlugin

public struct ArgumentMacro: ExtensionMacro, MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        // We want: extension <Type>: TableCapable {}
        let ext: ExtensionDeclSyntax = try! .init("""
        extension \(type): QueryArguments {}
        """)

        return [ext]
    }

    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // Collect stored properties (ignore computed / static)
        var fields: [String] = []

        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }

            // Skip 'static' properties
            if varDecl.modifiers.contains(where: { $0.name.text == "static" }) == true {
                continue
            }

            for binding in varDecl.bindings {
                guard binding.accessorBlock == nil else { continue }

                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }
                guard let typeSyntax = binding.typeAnnotation?.type else { continue }
                let typeName = typeSyntax.trimmedDescription
                if typeName != "DataType" {
                    continue
                }

                let name = pattern.identifier.text
                fields.append(name)
            }
        }

        let argsLiteral = fields.map({ "QueryArg(\"\($0)\", val.\($0))" }).joined(separator: ",")
        let switchLiteral = fields.enumerated().map({ "case \\Self.\($0.element): return \($0.offset)" }).joined(separator: "\n")
        
        var initStatement = ""
        if !fields.isEmpty {
            initStatement = "let val = Self()"
        }
            
        let decl: DeclSyntax = """
        public static func _index(forKeyPath kp: KeyPath<Self, DataType>) -> Int? {
            switch (kp) {
                \(raw: switchLiteral)
                default: return nil
            }
        }
        public static func _asArguments() -> [QueryArg] {
            \(raw: initStatement)
            return [\(raw: argsLiteral)]
        }
        """

        return [decl]
    }
}
