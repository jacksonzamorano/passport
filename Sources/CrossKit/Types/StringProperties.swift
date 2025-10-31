import Foundation

public struct StringProperties {
    var defaultValue: DefaultValue? = nil
    
    public enum DefaultValue {
        case empty
    }
    
}