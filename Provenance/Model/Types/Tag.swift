import Foundation

struct Tag: Hashable, Codable {
    var data: [TagResource]
    var links: Pagination
}

struct TagResource: Hashable, Codable, Identifiable {
    var type: String
    var id: String
    var relationships: AccountRelationship?
    
    init(type: String, id: String, relationships: AccountRelationship? = nil) {
        self.type = type
        self.id = id
        self.relationships = relationships
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TagResource, rhs: TagResource) -> Bool {
        lhs.id == rhs.id
    }
}
