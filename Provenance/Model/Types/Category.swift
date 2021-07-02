import Foundation

struct Category: Decodable {
    var data: [CategoryResource]
}

struct CategoryResource: Decodable, Identifiable {
    var type = "categories"
    var id: String
    var attributes: CategoryAttribute
    var relationships: CategoryRelationship
    var links: SelfLink?
    
    init(id: String, attributes: CategoryAttribute, relationships: CategoryRelationship) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
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

struct CategoryAttribute: Decodable {
    var name: String
}

struct CategoryRelationship: Decodable {
    var parent: CategoryRelationshipParent
    var children: CategoryRelationshipChildren
}

struct CategoryRelationshipParent: Decodable {
    var data: RelationshipData?
    var links: RelationshipLink?
}

struct CategoryRelationshipChildren: Decodable {
    var data: [RelationshipData]
    var links: RelationshipLink?
}
