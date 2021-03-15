import Foundation

struct Tag: Hashable, Codable {
    var data: [TagResource]
    var links: Pagination
}

struct TagResource: Hashable, Codable, Identifiable {
    var type: String
    var id: String
    var relationships: AccountRelationship?
}
