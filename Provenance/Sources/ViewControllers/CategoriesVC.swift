import UIKit
import IGListKit
import AsyncDisplayKit

final class CategoriesVC: ASViewController {
  // MARK: - Properties
  
  private lazy var searchController = UISearchController.categories(self)
  
  private let collectionNode = ASCollectionNode(collectionViewLayout: .twoColumnGridLayout)
  
  private lazy var collectionRefreshControl = UIRefreshControl(self, selector: #selector(refreshCategories))
  
  private var apiKeyObserver: NSKeyValueObservation?
  
  private var noCategories: Bool = false
  
  private var categories = [CategoryResource]() {
    didSet {
      noCategories = categories.isEmpty
      applySnapshot()
      collectionNode.view.refreshControl?.endRefreshing()
      searchController.searchBar.placeholder = "Search \(categories.count.description) \(categories.count == 1 ? "Category" : "Categories")"
    }
  }
  
  private var categoriesError = String()
  
  private var oldFilteredCategories = [CategoryResource]()
  
  private var filteredCategories: [CategoryResource] {
    return categories.filtered(searchBar: searchController.searchBar)
  }
  // MARK: - Life Cycle

  override init() {
    super.init(node: collectionNode)
  }

  deinit {
    removeObservers()
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureObservers()
    configureProperties()
    configureNavigation()
    configureCollectionNode()
    applySnapshot(override: true)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchCategories()
  }
}

// MARK: - Configuration

private extension CategoriesVC {
  private func configureProperties() {
    title = "Categories"
    definesPresentationContext = true
  }

  private func configureObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appMovedToForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
    apiKeyObserver = appDefaults.observe(\.apiKey, options: [.new]) { [weak self] (_, change) in
      guard let weakSelf = self, let value = change.newValue else { return }
      DispatchQueue.main.async {
        weakSelf.fetchCategories()
      }
    }
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self)
    apiKeyObserver?.invalidate()
    apiKeyObserver = nil
  }
  
  private func configureNavigation() {
    navigationItem.title = "Loading"
    navigationItem.largeTitleDisplayMode = .always
    navigationItem.backBarButtonItem = UIBarButtonItem(image: .trayFull)
    navigationItem.searchController = searchController
  }
  
  private func configureCollectionNode() {
    collectionNode.dataSource = self
    collectionNode.delegate = self
    collectionNode.view.refreshControl = collectionRefreshControl
    collectionNode.backgroundColor = .systemGroupedBackground
  }
}

// MARK: - Actions

private extension CategoriesVC {
  @objc private func appMovedToForeground() {
    fetchCategories()
  }
  
  @objc private func refreshCategories() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
      fetchCategories()
    }
  }
  
  private func applySnapshot(override: Bool = false) {
    let result = ListDiffPaths(
      fromSection: 0,
      toSection: 0,
      oldArray: oldFilteredCategories,
      newArray: filteredCategories,
      option: .equality
    ).forBatchUpdates()
    if result.hasChanges || override || !categoriesError.isEmpty || noCategories {
      if filteredCategories.isEmpty && categoriesError.isEmpty {
        if categories.isEmpty && !noCategories {
          collectionNode.view.backgroundView = .loadingView(frame: collectionNode.bounds)
        } else {
          collectionNode.view.backgroundView = .noContentView(frame: collectionNode.bounds, type: .categories)
        }
      } else {
        if !categoriesError.isEmpty {
          collectionNode.view.backgroundView = .errorView(frame: collectionNode.bounds, text: categoriesError)
        } else {
          if collectionNode.view.backgroundView != nil {
            collectionNode.view.backgroundView = nil
          }
        }
      }
      let batchUpdates = { [self] in
        collectionNode.deleteItems(at: result.deletes)
        collectionNode.insertItems(at: result.inserts)
        result.moves.forEach { collectionNode.moveItem(at: $0.from, to: $0.to) }
        collectionNode.reloadItems(at: result.updates)
        oldFilteredCategories = filteredCategories
      }
      collectionNode.performBatch(animated: true, updates: batchUpdates)
    }
  }
  
  private func fetchCategories() {
    UpFacade.listCategories { [self] (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(categories):
          display(categories)
        case let .failure(error):
          display(error)
        }
      }
    }
  }
  
  private func display(_ categories: [CategoryResource]) {
    categoriesError = ""
    self.categories = categories
    if navigationItem.title != "Categories" {
      navigationItem.title = "Categories"
    }
  }
  
  private func display(_ error: NetworkError) {
    categoriesError = error.description
    categories = []
    if navigationItem.title != "Error" {
      navigationItem.title = "Error"
    }
  }
}

// MARK: - ASCollectionDataSource

extension CategoriesVC: ASCollectionDataSource {
  func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
    return filteredCategories.count
  }

  func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
    let node = CategoryCellNode(category: filteredCategories[indexPath.item])
    return {
      node
    }
  }
}

// MARK: - ASCollectionDelegate

extension CategoriesVC: ASCollectionDelegate {
  func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
    collectionNode.deselectItem(at: indexPath, animated: true)
    let category = filteredCategories[indexPath.item]
    navigationController?.pushViewController(TransactionsByCategoryVC(category: category), animated: true)
  }
  
  func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let category = filteredCategories[indexPath.item]
    return UIContextMenuConfiguration(elements: [
      .copyCategoryName(category: category)
    ])
  }
}

// MARK: - UISearchBarDelegate

extension CategoriesVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    applySnapshot()
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if !searchBar.text!.isEmpty {
      searchBar.clear()
      applySnapshot()
    }
  }

  func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    if !searchBar.text!.isEmpty {
      applySnapshot()
    }
  }
}
