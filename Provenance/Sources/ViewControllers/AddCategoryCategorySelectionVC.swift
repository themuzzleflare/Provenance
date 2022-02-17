import UIKit
import AsyncDisplayKit
import IGListKit
import NotificationBannerSwift
import Alamofire
import MBProgressHUD

final class AddCategoryCategorySelectionVC: ASViewController {
  // MARK: - Properties

  private var transaction: TransactionResource

  private var fromTransactionDetail: Bool

  private lazy var searchController = UISearchController(self)

  private lazy var removeBarButtonItem = UIBarButtonItem(
    title: "Remove",
    style: .plain,
    target: self,
    action: #selector(removeCategory)
  )

  private let collectionNode = ASCollectionNode(collectionViewLayout: .twoColumnGrid)

  private var noCategories: Bool = false

  private var categories = [CategoryResource]() {
    didSet {
      noCategories = categories.isEmpty
      applySnapshot()
      collectionNode.view.refreshControl?.endRefreshing()
      searchController.searchBar.placeholder = preFilteredCategories.searchBarPlaceholder
    }
  }

  private var categoriesError = String()

  private var oldCategoryCellModels = [CategoryCellModel]()

  private var preFilteredCategories: [CategoryResource] {
    return categories.filter { (category) in
      return category.categoryTypeEnum == .child
    }
  }

  private var filteredCategories: [CategoryResource] {
    return preFilteredCategories.filtered(searchBar: searchController.searchBar)
  }

  // MARK: - Life Cycle

  init(transaction: TransactionResource, fromTransactionDetail: Bool = false) {
    self.transaction = transaction
    self.fromTransactionDetail = fromTransactionDetail
    super.init(node: collectionNode)
  }

  deinit {
    removeObserver()
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureObserver()
    configureSelf()
    configureNavigation()
    configureCollectionNode()
    applySnapshot(override: true)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchCategories()
    if fromTransactionDetail {
      navigationItem.leftBarButtonItem = .close(self, action: #selector(closeWorkflow))
    }
  }
}

// MARK: - Configuration

extension AddCategoryCategorySelectionVC {
  private func configureSelf() {
    title = "Category Selection"
    definesPresentationContext = true
  }

  private func configureObserver() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(appMovedToForeground),
                                           name: .willEnterForeground,
                                           object: nil)
  }

  private func removeObserver() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForeground, object: nil)
  }

  private func configureNavigation() {
    navigationItem.title = "Loading"
    navigationItem.prompt = "Only child categories are supported."
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.backButtonDisplayMode = .minimal
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
  }

  private func configureCollectionNode() {
    collectionNode.dataSource = self
    collectionNode.delegate = self
    collectionNode.view.refreshControl = UIRefreshControl(self, action: #selector(refreshCategories))
  }
}

// MARK: - Actions

extension AddCategoryCategorySelectionVC {
  @objc
  private func appMovedToForeground() {
    ASPerformBlockOnMainThread {
      self.fetchCategories()
    }
  }

  @objc
  private func refreshCategories() {
    fetchCategories()
  }

  @objc
  private func closeWorkflow() {
    navigationController?.dismiss(animated: true)
  }

  @objc
  private func removeCategory() {
    collectionNode.allowsSelection = false
    navigationItem.setRightBarButton(.activityIndicator, animated: false)
    Up.categorise(transaction: transaction) { (error) in
      if let error = error {
        GrowingNotificationBanner(
          title: "Failed",
          subtitle: error.underlyingError?.localizedDescription ?? error.localizedDescription,
          style: .danger,
          duration: 2.0
        ).show()
      } else {
        GrowingNotificationBanner(
          title: "Success",
          subtitle: "The category for \(self.transaction.attributes.description) was removed.",
          style: .success,
          duration: 2.0
        ).show()
      }
      self.navigationController?.popViewController(animated: true)
    }
  }

  private func applySnapshot(override: Bool = false) {
    let result = ListDiffPaths(
      fromSection: 0,
      toSection: 0,
      oldArray: oldCategoryCellModels,
      newArray: filteredCategories.cellModels,
      option: .equality
    ).forBatchUpdates()

    if result.hasChanges || override || !categoriesError.isEmpty || noCategories || searchController.searchBar.searchTextField.hasText {
      if filteredCategories.isEmpty && categoriesError.isEmpty {
        if categories.isEmpty && !noCategories {
          collectionNode.view.backgroundView = .loading(frame: collectionNode.bounds, contentType: .categories)
        } else {
          collectionNode.view.backgroundView = .noContent(frame: collectionNode.bounds, type: .categories)
        }
      } else {
        if !categoriesError.isEmpty {
          collectionNode.view.backgroundView = .error(frame: collectionNode.bounds, text: categoriesError)
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
        oldCategoryCellModels = filteredCategories.cellModels
      }

      collectionNode.performBatchUpdates(batchUpdates)
    }
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
    if navigationItem.title != "Select Category" {
      navigationItem.title = "Select Category"
    }
    if navigationItem.rightBarButtonItem == nil && !fromTransactionDetail {
      navigationItem.setRightBarButton(removeBarButtonItem, animated: true)
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

extension AddCategoryCategorySelectionVC: ASCollectionDataSource {
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

extension AddCategoryCategorySelectionVC: ASCollectionDelegate {
  func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
    let category = filteredCategories[indexPath.item]
    let hud = MBProgressHUD(view: view, animationType: .zoomIn)
    hud.label.attributedText = "Processing".styled(with: .provenance)
    collectionNode.deselectItem(at: indexPath, animated: true)
    view.addSubview(hud)
    hud.show(animated: true)
    Up.categorise(transaction: transaction, category: category) { (error) in
      if let error = error {
        GrowingNotificationBanner(
          title: "Failed",
          subtitle: error.underlyingError?.localizedDescription ?? error.localizedDescription,
          style: .danger,
          duration: 2.0
        ).show()
      } else {
        GrowingNotificationBanner(
          title: "Success",
          subtitle: "The category for \(self.transaction.attributes.description) was set to \(category.attributes.name).",
          style: .success,
          duration: 2.0
        ).show()
      }
      hud.hide(animated: true)
      if self.fromTransactionDetail {
        self.closeWorkflow()
      } else {
        self.navigationController?.popViewController(animated: true)
      }
    }
  }

  func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let category = filteredCategories[indexPath.item]
    return UIContextMenuConfiguration(elements: [
      .copyCategoryName(category: category)
    ])
  }
}

// MARK: - UISearchBarDelegate

extension AddCategoryCategorySelectionVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    applySnapshot()
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if searchBar.searchTextField.hasText {
      searchBar.clear()
      applySnapshot()
    }
  }
}
