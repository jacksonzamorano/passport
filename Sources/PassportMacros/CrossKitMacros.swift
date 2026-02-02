import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct CrossKitMacros: CompilerPlugin {
    var providingMacros: [Macro.Type] = [
        RecordMacro.self,
        ArgumentMacro.self,
        ModelMacro.self,
        EnumMacro.self
    ]
}
