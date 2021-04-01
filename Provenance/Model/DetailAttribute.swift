import UIKit

class DetailAttribute: Hashable {
    var id = UUID()
    var titleKey: String
    var titleValue: String
    
    init(titleKey: String, titleValue: String) {
        self.titleKey = titleKey
        self.titleValue = titleValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DetailAttribute, rhs: DetailAttribute) -> Bool {
        lhs.id == rhs.id
    }
}
