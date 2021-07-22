import Foundation

struct RelationshipData: Codable, Identifiable {
    var type: String

    var id: String
}

extension RelationshipData: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RelationshipData, rhs: RelationshipData) -> Bool {
        lhs.id == rhs.id
    }
}
