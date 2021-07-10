import UIKit

final class SearchController: UISearchController {
    // MARK: - Life Cycle
    
    override init(searchResultsController: UIViewController?) {
        super.init(searchResultsController: searchResultsController)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Configuration

private extension SearchController {
    private func configure() {
        log.verbose("configure")

        obscuresBackgroundDuringPresentation = false

        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search"
    }
}
