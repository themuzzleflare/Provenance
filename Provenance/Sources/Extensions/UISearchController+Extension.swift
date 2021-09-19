import Foundation
import UIKit

extension UISearchController {
  convenience init(_ delegate: UISearchBarDelegate) {
    self.init()
    self.searchBar.delegate = delegate
    self.obscuresBackgroundDuringPresentation = false
    self.searchBar.searchBarStyle = .minimal
    self.searchBar.placeholder = "Search"
  }

  static func accounts(_ delegate: UISearchBarDelegate) -> UISearchController {
    let searchController = UISearchController(delegate)
    searchController.searchBar.scopeButtonTitles = AccountTypeEnum.allCases.map { $0.description }
    return searchController
  }

  static func categories(_ delegate: UISearchBarDelegate) -> UISearchController {
    let searchController = UISearchController(delegate)
    searchController.searchBar.scopeButtonTitles = ["Parent", "Child"]
    return searchController
  }
}
