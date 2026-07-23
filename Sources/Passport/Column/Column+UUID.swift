import Foundation

extension Column {
    public static func uuid() -> Self {
        .init(dataType: .uuid)
    }
}
