import UIKit

class SearchController: UISearchController {
    // MARK: - Life Cycle
    
    override init(searchResultsController: UIViewController?) {
        super.init(searchResultsController: searchResultsController)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

// MARK: - Configuration

private extension SearchController {
    private func configure() {
        obscuresBackgroundDuringPresentation = false
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search"
    }
}
