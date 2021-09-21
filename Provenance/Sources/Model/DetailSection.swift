import Foundation

struct DetailSection: Identifiable {
  var id: Int
  
  var items: [DetailItem]
  
  init(id: Int, items: [DetailItem]) {
    self.id = id
    self.items = items
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
