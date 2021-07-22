import Foundation

struct DetailSection: Identifiable {
    var id: Int
    
    var attributes: [DetailAttribute]
    
    init(id: Int, attributes: [DetailAttribute]) {
        self.id = id
        self.attributes = attributes
    }
}

extension DetailSection: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DetailSection, rhs: DetailSection) -> Bool {
        lhs.id == rhs.id
    }
}
