extension String {
    func snakeToPascalCase() -> String {
        return self.split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined()
    }
    func snakeToCamelCase() -> String {
        return self.split(separator: "_")
            .enumerated()
            .map { index, component in
                index == 0 ? String(component) : component.prefix(1).uppercased() + component.dropFirst()
            }
            .joined()
    }
}
