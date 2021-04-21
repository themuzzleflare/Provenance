import Foundation

class DetailAttribute: Hashable {
    var id = UUID()
    var key: String
    var value: String
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DetailAttribute, rhs: DetailAttribute) -> Bool {
        lhs.id == rhs.id
    }
}
