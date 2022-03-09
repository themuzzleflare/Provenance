import UIKit
import AsyncDisplayKit
import IGListKit
import Alamofire

final class CategoriesVC: ASViewController, UIProtocol {
  // MARK: - Properties

  var state: UIState = .initialLoad {
    didSet {
      if oldValue != state {
        UIUpdates.updateUI(state: state, contentType: .categories, collection: .collectionNode(collectionNode))
      }
    }
  }

  private lazy var searchController = UISearchController.categories(self)

  private let collectionNode = ASCollectionNode(collectionViewLayout: .twoColumnGrid)

  private lazy var categoryFilter: CategoryTypeEnum = Store.provenance.appCategoryFilter {
    didSet {
      if Store.provenance.categoryFilter != categoryFilter.rawValue {
        Store.provenance.categoryFilter = categoryFilter.rawValue
      } else {
        if searchController.searchBar.selectedScopeButtonIndex != categoryFilter.rawValue {
          searchController.searchBar.selectedScopeButtonIndex = categoryFilter.rawValue
        }
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

  private var oldCategoryCellModels = [ListDiffable]()

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
    configureSelf()
    configureObservers()
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

extension CategoriesVC {
  private func configureSelf() {
    title = "Categories"
    definesPresentationContext = true
  }

  private func configureObservers() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(appMovedToForeground),
                                           name: .willEnterForeground,
                                           object: nil)
    apiKeyObserver = Store.provenance.observe(\.apiKey, options: .new) { [weak self] (_, _) in
      ASPerformBlockOnMainThread {
        self?.fetchCategories()
      }
    }
    categoryFilterObserver = Store.provenance.observe(\.categoryFilter, options: .new) { [weak self] (_, change) in
      ASPerformBlockOnMainThread {
        guard let value = change.newValue, let categoryFilter = CategoryTypeEnum(rawValue: value) else { return }
        self?.categoryFilter = categoryFilter
      }
    }
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForeground, object: nil)
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

extension CategoriesVC {
  @objc
  private func appMovedToForeground() {
    ASPerformBlockOnMainThread {
      self.fetchCategories()
    }
  }

  @objc
  private func refreshCategories() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.fetchCategories()
    }
  }

  @objc
  private func modifyCategories() {
    let viewController = NavigationController(rootViewController: AddCategoryTransactionSelectionVC())
    present(.fullscreen(viewController), animated: true)
  }

  private func applySnapshot(override: Bool = false) {
    UIUpdates.applySnapshot(oldArray: &oldCategoryCellModels,
                            newArray: filteredCategories.cellModels,
                            override: override,
                            state: &state,
                            contents: categories,
                            filteredContents: filteredCategories,
                            noContent: noCategories,
                            error: categoriesError,
                            contentType: .categories,
                            collection: .collectionNode(collectionNode))
  }

  private func fetchCategories() {
    Up.listCategories { (result) in
      switch result {
      case let .success(categories):
        self.display(categories)
      case let .failure(error):
        self.display(error)
      }
    }
  }

  private func display(_ categories: [CategoryResource]) {
    categoriesError = ""
    self.categories = categories
    if navigationItem.title != "Categories" {
      navigationItem.title = "Categories"
    }
    if navigationItem.rightBarButtonItem == nil {
      navigationItem.setRightBarButton(.add(self, action: #selector(modifyCategories)), animated: true)
    }
  }

  private func display(_ error: AFError) {
    categoriesError = error.underlyingError?.localizedDescription ?? error.localizedDescription
    categories.removeAll()
    if navigationItem.title != "Error" {
      navigationItem.title = "Error"
    }
    if navigationItem.rightBarButtonItem != nil {
      navigationItem.setRightBarButton(nil, animated: true)
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
    return {
      CategoryCellNode(model: category.cellModel)
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
    return UIContextMenuConfiguration(
      previewProvider: {
        TransactionsByCategoryVC(category: category)
      },
      elements: [
        .copyCategoryName(category: category)
      ]
    )
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
