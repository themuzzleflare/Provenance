import Foundation
import UIKit

struct DetailItem {
  let id: String
  let value: String
}

// MARK: - Hashable

extension DetailItem: Hashable {
  static func == (lhs: DetailItem, rhs: DetailItem) -> Bool {
    return lhs.id == rhs.id && lhs.value == rhs.value
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(value)
  }
}

// MARK: -

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
    case "Transaction ID", "Raw Text", "Account ID":
      return .sfMonoRegular(size: .labelFontSize)
    default:
      return .circularStdBook(size: .labelFontSize)
    }
  }
}
