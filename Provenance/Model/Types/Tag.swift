import Foundation

#if canImport(IGListKit)
import IGListKit
#endif

struct Tag: Decodable {
    var data: [TagResource] // The list of tags returned in this response.

    var links: Pagination
}

class TagResource: Decodable, Identifiable {
    var type = "tags" // The type of this resource: tags

    var id: String // The label of the tag, which also acts as the tag’s unique identifier.

    var relationships: TagRelationship?
    
    init(id: String) {
        self.id = id
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

#if canImport(IGListKit)
extension TagResource: ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        id as NSObjectProtocol
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? TagResource else {
            return false
        }
        return self.id == object.id
    }
}
#endif

struct TagRelationship: Decodable {
    var transactions: TransactionsLinksObject
}

struct ModifyTags: Codable {
    var data: [TagInputResourceIdentifier] // The tags to add to or remove from the transaction.
}

struct TagInputResourceIdentifier: Codable, Identifiable {
    var type = "tags" // The type of this resource: tags
    
    var id: String // The label of the tag, which also acts as the tag’s unique identifier.
}
