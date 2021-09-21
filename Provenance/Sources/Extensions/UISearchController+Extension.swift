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
    searchController.searchBar.scopeButtonTitles = AccountTypeOptionEnum.allCases.map { $0.description }
    searchController.searchBar.selectedScopeButtonIndex = appDefaults.accountFilter
    return searchController
  }
  
  static func categories(_ delegate: UISearchBarDelegate) -> UISearchController {
    let searchController = UISearchController(delegate)
    searchController.searchBar.scopeButtonTitles = CategoryTypeEnum.allCases.map { $0.description }
    searchController.searchBar.selectedScopeButtonIndex = appDefaults.categoryFilter
    return searchController
  }
}
