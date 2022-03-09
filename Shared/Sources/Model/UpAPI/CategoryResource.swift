import Foundation
import UIKit

struct CategoryResource: Codable, Identifiable {
  /// The type of this resource: `categories`
  var type = "categories"

  /// The unique identifier for this category.
  /// This is a human-readable but URL-safe value.
  var id: String

  var attributes: CategoryAttributes

  var relationships: CategoryRelationships

  var links: SelfLink?
}

// MARK: - CustomStringConvertible

extension CategoryResource: CustomStringConvertible {
  var description: String {
    return attributes.name
  }
}

// MARK: -

extension CategoryResource {
  var categoryInputResourceIdentifier: CategoryInputResourceIdentifier {
    return CategoryInputResourceIdentifier(id: id)
  }

  var categoryTypeEnum: CategoryTypeEnum {
    return relationships.parent.data == nil ? .parent : .child
  }

  var categoryType: CategoryType {
    return CategoryType(identifier: id, display: attributes.name)
  }
}

// MARK: -

extension Array where Element == CategoryResource {
  func filtered(filter: CategoryTypeEnum, searchBar: UISearchBar) -> [CategoryResource] {
    return self.filter { (category) in
      return !searchBar.searchTextField.hasText ||
      (category.attributes.name.localizedStandardContains(searchBar.text!) && category.categoryTypeEnum == filter)
    }
  }

  func filtered(searchBar: UISearchBar) -> [CategoryResource] {
    return self.filter { (category) in
      return !searchBar.searchTextField.hasText || category.attributes.name.localizedStandardContains(searchBar.text!)
    }
  }

  var searchBarPlaceholder: String {
    return "Search \(self.count.description) \(self.count == 1 ? "Category" : "Categories")"
  }

  var categoryTypes: [CategoryType] {
    return self.map { $0.categoryType }
  }
}
