import Foundation

#if canImport(IGListKit)
import IGListKit
#endif

class RelationshipData: Decodable, Identifiable {
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

#if canImport(IGListKit)
extension RelationshipData: ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        id as NSObjectProtocol
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? RelationshipData else {
            return false
        }
        return self.id == object.id
    }
}
#endif
