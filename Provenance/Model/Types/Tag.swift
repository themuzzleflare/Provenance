import Foundation

struct Tag: Decodable {
    var data: [TagResource]
    var links: Pagination
}

struct TagResource: Decodable, Identifiable {
    var type: String
    var id: String
    var relationships: AccountRelationship?
    
    init(type: String, id: String, relationships: AccountRelationship? = nil) {
        self.type = type
        self.id = id
        self.relationships = relationships
    }
}

extension TagResource: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TagResource, rhs: TagResource) -> Bool {
        lhs.id == rhs.id
    }
}

struct ModifyTags: Codable {
    var data: [TagInputResourceIdentifier] // The tags to add to or remove from the transaction.
}

struct TagInputResourceIdentifier: Codable, Identifiable {
    var type = "tags" // The type of this resource: tags
    var id: String // The label of the tag, which also acts as the tag’s unique identifier.
}
