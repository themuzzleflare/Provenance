import Foundation

struct Category: Hashable, Codable {
    var data: [CategoryResource]
}

struct CategoryResource: Hashable, Codable, Identifiable {
    var type: String
    var id: String
    var attributes: CategoryAttribute
    var relationships: CategoryRelationship
    var links: SelfLink?
    
    init(type: String, id: String, attributes: CategoryAttribute, relationships: CategoryRelationship, links: SelfLink? = nil) {
        self.type = type
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
        self.links = links
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CategoryResource, rhs: CategoryResource) -> Bool {
        lhs.id == rhs.id
    }
}

struct CategoryAttribute: Hashable, Codable {
    var name: String
}

struct CategoryRelationship: Codable, Hashable {
    var parent: CategoryRelationshipParent
    var children: CategoryRelationshipChildren
}

struct CategoryRelationshipParent: Codable, Hashable {
    var data: RelationshipData?
    var links: RelationshipLink?
}

struct CategoryRelationshipChildren: Codable, Hashable {
    var data: [RelationshipData]
    var links: RelationshipLink?
}
