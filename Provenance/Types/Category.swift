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
