import Foundation

public enum SchemaItem {
    case table(any Table),
         query(Query),
         migration(Migration)
}


public protocol IntoSchemaItem {
    func toSchemaItem() -> SchemaItem
}

@resultBuilder
public enum SchemaBuilder {
    public static func buildBlock(_ components: any IntoSchemaItem...)
        -> [SchemaItem]
    {
        return components.map({ $0.toSchemaItem() })
    }
}
