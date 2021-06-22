import Foundation

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
