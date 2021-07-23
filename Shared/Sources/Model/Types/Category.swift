import Foundation

struct Category: Codable {
    var data: [CategoryResource] // The list of categories returned in this response.
}

struct CategoryResource: Codable, Identifiable {
    var type = "categories" // The type of this resource: categories

    var id: String // The unique identifier for this category. This is a human-readable but URL-safe value.

    var attributes: CategoryAttribute

    var relationships: CategoryRelationship?

    var links: SelfLink?

    init(id: String, attributes: CategoryAttribute) {
        self.id = id
        self.attributes = attributes
    }
}

extension CategoryResource: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CategoryResource, rhs: CategoryResource) -> Bool {
        lhs.id == rhs.id
    }
}

struct CategoryAttribute: Codable {
    var name: String // The name of this category as seen in the Up application.
}

struct CategoryRelationship: Codable {
    var parent: CategoryRelationshipParent

    var children: CategoryRelationshipChildren
}

struct CategoryRelationshipParent: Codable {
    var data: RelationshipData?

    var links: RelatedLink?
}

struct CategoryRelationshipChildren: Codable {
    var data: [RelationshipData]

    var links: RelatedLink?
}
