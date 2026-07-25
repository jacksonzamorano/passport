import Foundation

extension Column {
    public static func timezonedDate() -> Self {
        .init(dataType: .dateWithTimezone)
    }
    public static func date() -> Self {
        .init(dataType: .date)
    }
}
