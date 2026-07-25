import Foundation

extension Column {
    public static func timezonedDate() -> Self {
        .init(dataType: .dateWithTimezone)
    }
}
