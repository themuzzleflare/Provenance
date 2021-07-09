import Foundation

struct DetailAttribute: Identifiable {
    var id: String

    var value: String
    
    init(id: String, value: String) {
        self.id = id
        self.value = value
    }
}

extension DetailAttribute: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(value)
    }

    static func == (lhs: DetailAttribute, rhs: DetailAttribute) -> Bool {
        lhs.id == rhs.id
    }
}
