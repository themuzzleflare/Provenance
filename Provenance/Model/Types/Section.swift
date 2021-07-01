import Foundation
import IGListKit

class Section {
    var id = UUID()
    var title: String
    var detailAttributes: [DetailAttribute]
    
    init(title: String, detailAttributes: [DetailAttribute]) {
        self.title = title
        self.detailAttributes = detailAttributes
    }
}

extension Section: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Section, rhs: Section) -> Bool {
        lhs.id == rhs.id
    }
}

extension Section: ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        id as NSObjectProtocol
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? Section else {
            return false
        }
        return self.id == object.id
    }
}
