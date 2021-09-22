import Foundation
import UIKit

struct DetailItem: Identifiable {
  var id: String
  
  var value: String
  
  init(id: String, value: String) {
    self.id = id
    self.value = value
  }
}

extension DetailItem: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(value)
  }
  
  static func == (lhs: DetailItem, rhs: DetailItem) -> Bool {
    lhs.id == rhs.id
  }
}

extension DetailItem {
  var cellSelectionStyle: UITableViewCell.SelectionStyle {
    switch id {
    case "Account", "Transfer Account", "Parent Category", "Category", "Tags":
      return .default
    default:
      return .none
    }
  }
  
  var cellAccessoryType: UITableViewCell.AccessoryType {
    switch id {
    case "Account", "Transfer Account", "Parent Category", "Category", "Tags":
      return .disclosureIndicator
    default:
      return .none
    }
  }
  
  var valueFont: UIFont {
    switch id {
    case "Raw Text", "Account ID":
      return .sfMonoRegular(size: UIFont.labelFontSize)
    default:
      return .circularStdBook(size: UIFont.labelFontSize)
    }
  }
}
