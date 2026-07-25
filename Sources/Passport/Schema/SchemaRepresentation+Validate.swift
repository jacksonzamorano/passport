import Foundation

extension SchemaRepresentation {
    func validate() -> Bool {
        var valid = true
        
        let schemaTimeStart = Date()
        for query in self.queries {
            do {
                try query.base.validate()
            } catch {
                print("[\(error.codeString)] (\(query.base.identity.queryName)): \(error.description)")
                valid = false
            }
        }
        
        let schemaSecondsTaken = -schemaTimeStart.timeIntervalSinceNow
        print(String(format: "Validated schema in %.2f seconds.", schemaSecondsTaken))
        return valid
    }
}
