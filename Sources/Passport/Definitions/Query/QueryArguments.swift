import Foundation

public protocol QueryArguments: Sendable {
    init()
    static func _index(forKeyPath kp: KeyPath<Self, DataType>) -> Int?
    static func _asArguments() -> [QueryArg]
}

@attached(extension, conformances: QueryArguments)
@attached(member, names: named(_index), named(_asArguments))
public macro Argument() = #externalMacro(
    module: "PassportMacros",
    type: "ArgumentMacro"
)
