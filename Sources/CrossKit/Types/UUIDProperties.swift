import Foundation

public struct UUIDProperties {
    public init(defaultValue: UUIDProperties.DefaultValue? = nil) {
        self.defaultValue = defaultValue
    }
    
    var defaultValue: DefaultValue? = nil
    
    public enum DefaultValue {
        case new
    }
    
}