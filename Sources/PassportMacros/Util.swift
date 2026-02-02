import Foundation

extension String {
    func lowerCamelToSnakecase() -> String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: self.utf16.count)
        let snakeCase = regex.stringByReplacingMatches(
            in: self,
            range: range,
            withTemplate: "$1_$2"
        )
        return snakeCase.lowercased()
    }
}
