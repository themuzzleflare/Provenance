import Foundation
import IGListKit

class DetailAttribute {
    var id = UUID()

    var key: String

    var value: String
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

extension DetailAttribute: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DetailAttribute, rhs: DetailAttribute) -> Bool {
        lhs.id == rhs.id
    }
}

extension DetailAttribute: ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        id as NSObjectProtocol
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? DetailAttribute else {
            return false
        }
        return self.id == object.id
    }
}
