import IGListDiffKit
import AsyncDisplayKit
import Alamofire

final class CategoriesVC: ASViewController {
    // MARK: - Properties
  
  private lazy var searchController = UISearchController.categories(self)
  
  private let collectionNode = ASCollectionNode(collectionViewLayout: .twoColumnGridLayout)
  
  private var categoryFilter: CategoryTypeEnum = ProvenanceApp.userDefaults.appCategoryFilter {
    didSet {
      if ProvenanceApp.userDefaults.categoryFilter != categoryFilter.rawValue {
        ProvenanceApp.userDefaults.categoryFilter = categoryFilter.rawValue
      }
      if searchController.searchBar.selectedScopeButtonIndex != categoryFilter.rawValue {
        searchController.searchBar.selectedScopeButtonIndex = categoryFilter.rawValue
      }
    }
  }
  
  private var apiKeyObserver: NSKeyValueObservation?
  
  private var categoryFilterObserver: NSKeyValueObservation?
  
  private var noCategories: Bool = false
  
  private var categories = [CategoryResource]() {
    didSet {
      noCategories = categories.isEmpty
      applySnapshot()
      collectionNode.view.refreshControl?.endRefreshing()
      searchController.searchBar.placeholder = categories.searchBarPlaceholder
    }
  }
  
  private var categoriesError = String()
  
  private var oldCategoryCellModels = [CategoryCellModel]()
  
  private var filteredCategories: [CategoryResource] {
    return categories.filtered(filter: categoryFilter, searchBar: searchController.searchBar)
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
    configureSelf()
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
  private func configureSelf() {
    title = "Categories"
    definesPresentationContext = true
  }
  
  private func configureObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: .willEnterForegroundNotification, object: nil)
    apiKeyObserver = ProvenanceApp.userDefaults.observe(\.apiKey, options: .new) { [weak self] (_, _) in
      guard let weakSelf = self else { return }
      DispatchQueue.main.async {
        weakSelf.fetchCategories()
      }
    }
    categoryFilterObserver = ProvenanceApp.userDefaults.observe(\.categoryFilter, options: .new) { [weak self] (_, change) in
      guard let weakSelf = self, let value = change.newValue, let categoryFilter = CategoryTypeEnum(rawValue: value) else { return }
      weakSelf.categoryFilter = categoryFilter
    }
  }
  
  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForegroundNotification, object: nil)
    apiKeyObserver?.invalidate()
    apiKeyObserver = nil
    categoryFilterObserver?.invalidate()
    categoryFilterObserver = nil
  }
  
  private func configureNavigation() {
    navigationItem.title = "Loading"
    navigationItem.largeTitleDisplayMode = .always
    navigationItem.backBarButtonItem = .trayFull
    navigationItem.searchController = searchController
  }
  
  private func configureCollectionNode() {
    collectionNode.dataSource = self
    collectionNode.delegate = self
    collectionNode.view.refreshControl = UIRefreshControl(self, action: #selector(refreshCategories))
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
      oldArray: oldCategoryCellModels,
      newArray: filteredCategories.categoryCellModels,
      option: .equality
    ).forBatchUpdates()
    if result.hasChanges || override || !categoriesError.isEmpty || noCategories {
      if filteredCategories.isEmpty && categoriesError.isEmpty {
        if categories.isEmpty && !noCategories {
          collectionNode.view.backgroundView = .loadingView(frame: collectionNode.bounds, contentType: .categories)
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
        oldCategoryCellModels = filteredCategories.categoryCellModels
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
    categoriesError = .emptyString
    self.categories = categories
    if navigationItem.title != "Categories" {
      navigationItem.title = "Categories"
    }
  }
  
  private func display(_ error: AFError) {
    categoriesError = error.errorDescription ?? error.localizedDescription
    categories.removeAll()
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
    let category = filteredCategories[indexPath.item]
    let node = CategoryCellNode(category: category)
    return {
      node
    }
  }
}

  // MARK: - ASCollectionDelegate

extension CategoriesVC: ASCollectionDelegate {
  func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
    let category = filteredCategories[indexPath.item]
    let viewController = TransactionsByCategoryVC(category: category)
    collectionNode.deselectItem(at: indexPath, animated: true)
    navigationController?.pushViewController(viewController, animated: true)
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
    if searchBar.searchTextField.hasText {
      searchBar.clear()
      applySnapshot()
    }
  }
  
  func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    if let value = CategoryTypeEnum(rawValue: selectedScope) {
      categoryFilter = value
    }
    if searchBar.searchTextField.hasText {
      applySnapshot()
    }
  }
}