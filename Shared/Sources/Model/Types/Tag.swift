import Foundation

struct Tag: Codable {
    var data: [TagResource] // The list of tags returned in this response.

    var links: Pagination
}

struct TagResource: Codable, Identifiable {
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

struct TagRelationship: Codable {
    var transactions: TransactionsLinksObject
}

struct ModifyTags: Codable {
    var data: [TagInputResourceIdentifier] // The tags to add to or remove from the transaction.
}

struct TagInputResourceIdentifier: Codable, Identifiable {
    var type = "tags" // The type of this resource: tags

    var id: String // The label of the tag, which also acts as the tag’s unique identifier.
}

struct SortedTags: Identifiable {
    var id: String

    var tags: [TagResource]

    init(id: String, tags: [TagResource]) {
        self.id = id
        self.tags = tags
    }
}

extension SortedTags: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SortedTags, rhs: SortedTags) -> Bool {
        lhs.id == rhs.id
    }
}
