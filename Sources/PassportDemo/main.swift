import Passport
import Foundation

let postgres = PostgreSQL()
print(try! postgres.buildSelectQuery(query: SelectPostsQuery))
print(try! postgres.buildInsertQuery(query: InsertUserQuery))
