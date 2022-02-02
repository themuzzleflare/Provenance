import UIKit

extension UISearchController {
  convenience init(_ delegate: UISearchBarDelegate) {
    self.init()
    self.searchBar.delegate = delegate
    self.obscuresBackgroundDuringPresentation = false
    self.searchBar.searchBarStyle = .minimal
    self.searchBar.autocorrectionType = .no
    self.searchBar.autocapitalizationType = .none
    self.searchBar.spellCheckingType = .no
  }

  static func accounts(_ delegate: UISearchBarDelegate) -> UISearchController {
    let searchController = UISearchController(delegate)
    searchController.searchBar.scopeButtonTitles = AccountTypeOptionEnum.allCases.names
    searchController.searchBar.selectedScopeButtonIndex = Store.provenance.accountFilter
    return searchController
  }

  static func categories(_ delegate: UISearchBarDelegate) -> UISearchController {
    let searchController = UISearchController(delegate)
    searchController.searchBar.scopeButtonTitles = CategoryTypeEnum.allCases.names
    searchController.searchBar.selectedScopeButtonIndex = Store.provenance.categoryFilter
    return searchController
  }
}
