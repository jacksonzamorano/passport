import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftSyntaxMacros
import SwiftCompilerPlugin


let joinTypeValidDeclarations = ["join"]
let queryTypeValidDeclarations = ["select", "insert", "update", "delete"]

func buildModel(syntax: StructDeclSyntax, attribute: AttributeSyntax, context: MacroExpansionContext, inRecordMode: Bool) -> [DeclSyntax] {
    var recordType: ExprSyntax?
    var baseType: ExprSyntax?
    
    if inRecordMode {
        if let args = attribute.arguments,
           case let .argumentList(labeledArgs) = args {
            
            for arg in labeledArgs {
                let expr = arg.expression
                
                if arg.label?.text == "type" {
                    recordType = expr
                }
                
                if let call = expr.as(FunctionCallExprSyntax.self),
                   let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self) {
                    
                    let caseName = memberAccess.declName.baseName.text
                    guard caseName == "query" || caseName == "view" else { continue }
                    if let lastArg = call.arguments.last {
                        if let member = lastArg.expression.as(MemberAccessExprSyntax.self) {
                            baseType = member.base!
                        }
                    }
                }
            }
        }
    }
    
    var fields: [NamedContent] = []
    var queries: [String] = []
    var joins: [String] = []
    
    for member in syntax.memberBlock.members {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
        
        let isStatic = varDecl.modifiers.contains(where: { $0.name.text == "static" })
        
        for binding in varDecl.bindings {
            guard binding.accessorBlock == nil else { continue }
            
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }
            
            let name = pattern.identifier.text
            guard let initializer = binding.initializer?.value else {
                continue
            }
            if !isStatic {
                fields
                    .append(
                        NamedContent(
                            swiftName: name,
                            internalName: name.lowerCamelToSnakecase(),
                            definition: binding.initializer!.value.trimmedDescription
                        )
                    )
            }
            if inRecordMode, isStatic, let functionCall = initializer.as(FunctionCallExprSyntax.self),
               let functionName = functionCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text {
                if joinTypeValidDeclarations.contains(functionName) {
                    joins.append(name)
                } else if queryTypeValidDeclarations.contains(functionName) {
                    queries.append(name)
                } else {
                    context
                        .diagnose(
                            .init(
                                node: pattern,
                                message: MacroExpansionErrorMessage(
                                    "Unknown instruction: \(Syntax(initializer).trimmedDescription)"
                                )
                            )
                        )
                }
            }
        }
    }
    let allFields = fields.map({ "NamedField(\"\($0.internalName)\", \($0.definition))"}).joined(
        separator: ","
    )
    let fieldIndexes = fields.enumerated().map({ "case \\Self.\($0.element.swiftName): return \($0.offset)" }).joined(
        separator: "\n\t\t"
    )
    let field = fields.enumerated().map({ "case \\Self.\($0.element.swiftName): return Self.fields[\($0.offset)]" }).joined(
        separator: "\n\t\t"
    )
    let schemaEntity = inRecordMode ? "SchemaEntity.record(Self.self)" : "SchemaEntity.model(Self.self)"
    var blocks: [DeclSyntax] = ["""
        public static let schemaEntity: SchemaEntity = \(raw: schemaEntity)
        public static let name = "\(raw: syntax.name.text)"

        public static let fields: [NamedField] = [\(raw: allFields)]
        public static func index(forKeyPath kp: KeyPath<Self, Field>) -> Int {
            switch (kp) {
                \(raw: fieldIndexes)
                default: return 0
            }
        }
        public static func field(forKeyPath kp: KeyPath<Self, Field>) -> NamedField? {
            switch (kp) {
                \(raw: field)
                default: return nil
            }
        }
        """]
    
    if inRecordMode {
        let queryLiteral = queries.map({ "NamedQuery(\"\($0)\", Self.\($0))" }).joined(separator: ",")
        let allJoins = joins.map({ "AnyJoin(Self.\($0))"}).joined(separator: ",")
        blocks.append("""
            public static let recordType: RecordType = \(recordType!)
            public static var queries: [NamedQuery] {
                [\(raw: queryLiteral)]
            }
            public static var joins: [AnyJoin] {
                [\(raw: allJoins)]
            }
            public static func fromExpression(_ type: DataType, _ expression: @Sendable @escaping () -> QueryStringSingleLocationCondition<Self>) -> Field {
                return Field(dataType: type, expression: expression)
            }
            public static func select<A: QueryArguments>(with arguments: A.Type, _ build: @Sendable @escaping (SelectQueryBuilder<Self, A>) -> Void) -> Query {
                return Query.select(Self.self, arguments) { builder in
                    build(builder)
                }
            }
            """)
        if let baseType {
            blocks.append("""
                typealias BaseValue = \(baseType)
                        
                public static func fromBase(_ path: KeyPath<BaseValue, Field>) -> Field {
                    return Field(fromBase: path)
                }
                public static func fromJoin<T: Record>(_ localJoin: KeyPath<Self.Type, Join<T>>, _ path: KeyPath<T, Field>) -> Field {
                    return Field(withJoin: Self.self[keyPath: localJoin], field: path)
                }
                public static func join<T: Record>(_ foreign: T.Type, type: JoinType, _ condition: @escaping JoinConditionFn<BaseValue, Self, T>) -> Join<T> {
                    return Join(BaseValue.recordType.name, BaseValue.self, Self.recordType.name, Self.self, foreign.recordType.name, T.self, joinType: type, condition: condition)
                } 
                public static func insert(_ args: KeyPath<BaseValue, Field>...) -> Query {
                    return Query.insert(BaseValue.self, args)
                }
                public static func update<A: QueryArguments>(with arguments: A.Type, _ build: @Sendable @escaping (UpdateQueryBuilder<BaseValue, A>) -> Void) -> Query {
                    return Query.update(BaseValue.self, arguments) { builder in
                        build(builder)
                    }
                }
                public static func delete<A: QueryArguments>(with arguments: A.Type, _ build: @Sendable @escaping (DeleteQueryBuilder<BaseValue, A>) -> Void) -> Query {
                    return Query.delete(BaseValue.self, arguments) { builder in
                        build(builder)
                    }
                }
                """)
        } else {
            blocks.append("""
                public static func insert(_ args: KeyPath<Self, Field>...) -> Query {
                    return Query.insert(Self.self, args)
                }
                public static func update<A: QueryArguments>(with arguments: A.Type, _ build: @Sendable @escaping (UpdateQueryBuilder<Self, A>) -> Void) -> Query {
                    return Query.update(Self.self, arguments) { builder in
                        build(builder)
                    }
                }
                public static func delete<A: QueryArguments>(with arguments: A.Type, _ build: @Sendable @escaping (DeleteQueryBuilder<Self, A>) -> Void) -> Query {
                    return Query.delete(Self.self, arguments) { builder in
                        build(builder)
                    }
                }
                """)
        }
    }
    
    return blocks
}
