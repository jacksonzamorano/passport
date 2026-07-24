import Passport
import Foundation

let postgres = PostgreSQL()
print(try! postgres.buildQuery(query: .select(.init(configuration: SelectPostsQuery())), context: RenderContext()))
print(try! postgres.buildQuery(query: .select(.init(configuration: InsertGetPostWithEmail())), context: RenderContext()))
//print(try! postgres.buildUpdateQuery(query: UpdateLastPostID))
