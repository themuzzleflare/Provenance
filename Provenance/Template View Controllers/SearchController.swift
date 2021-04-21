import UIKit

class SearchController: UISearchController {
    override init(searchResultsController: UIViewController?) {
        super.init(searchResultsController: searchResultsController)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

extension SearchController {
    private func configure() {
        obscuresBackgroundDuringPresentation = false
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search"
    }
}
