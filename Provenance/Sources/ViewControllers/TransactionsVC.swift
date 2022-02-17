import UIKit
import AsyncDisplayKit
import IGListKit
import Alamofire

final class TransactionsVC: ASViewController {
  // MARK: - Properties

  private lazy var filterBarButtonItem = UIBarButtonItem(image: .sliderHorizontal3, menu: filterMenu)

  private lazy var searchController = UISearchController(self)

  private lazy var adapter = ListAdapter(updater: ListAdapterUpdater(), viewController: self)

  private let collectionNode = ASCollectionNode(collectionViewLayout: .flowLayout)

  private let spinToken = "spinner"

  private var apiKeyObserver: NSKeyValueObservation?

  private var dateStyleObserver: NSKeyValueObservation?

  private var settledOnlyObserver: NSKeyValueObservation?

  private var paginationCursorObserver: NSKeyValueObservation?

  private var transactionGroupingObserver: NSKeyValueObservation?

  private var cursor: String?

  private var noTransactions: Bool = false

  private var transactionsError = String()

  var sinceDate: Date? {
    didSet {
      fetchTransactions()
      filterUpdates()
    }
  }

  var untilDate: Date? {
    didSet {
      fetchTransactions()
      filterUpdates()
    }
  }

  private lazy var transactionGrouping: TransactionGroupingEnum = Store.provenance.appTransactionGrouping {
    didSet {
      if Store.provenance.transactionGrouping != transactionGrouping.rawValue {
        Store.provenance.transactionGrouping = transactionGrouping.rawValue
      }
      filterUpdates()
    }
  }

  private var transactions = [TransactionResource]() {
    didSet {
      transactionsUpdates()
    }
  }

  private var filteredTransactions: [TransactionResource] {
    return preFilteredTransactions.filtered(searchBar: searchController.searchBar)
  }

  private var preFilteredTransactions: [TransactionResource] {
    return transactions.filter { (transaction) in
      return (!showSettledOnly || transaction.attributes.status.isSettled) &&
      (categoryFilter == .all || categoryFilter.rawValue == transaction.relationships.category.data?.id)
    }
  }

  private lazy var categoryFilter: TransactionCategory = Store.provenance.appSelectedCategory {
    didSet {
      if Store.provenance.selectedCategory != categoryFilter.rawValue {
        Store.provenance.selectedCategory = categoryFilter.rawValue
      }
      filterUpdates()
    }
  }

  private lazy var showSettledOnly: Bool = Store.provenance.settledOnly {
    didSet {
      if Store.provenance.settledOnly != showSettledOnly {
        Store.provenance.settledOnly = showSettledOnly
      }
      filterUpdates()
    }
  }

  private var loading: Bool = false

  // MARK: - Life Cycle

  override init() {
    super.init(node: collectionNode)
    adapter.setASDKCollectionNode(collectionNode)
    adapter.dataSource = self
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
    configureCollectionNode()
    configureSelf()
    configureNavigation()
    fetchingTasks()
  }
}

// MARK: - Configuration

extension TransactionsVC {
  private func configureCollectionNode() {
    collectionNode.view.refreshControl = UIRefreshControl(self, action: #selector(refreshTransactions))
  }

  private func configureSelf() {
    title = "Transactions"
    definesPresentationContext = true
  }

  private func configureObservers() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(appMovedToForeground),
                                           name: .willEnterForeground,
                                           object: nil)
    apiKeyObserver = Store.provenance.observe(\.apiKey, options: .new) { [weak self] (_, _) in
      ASPerformBlockOnMainThread {
        self?.fetchingTasks()
      }
    }
    dateStyleObserver = Store.provenance.observe(\.dateStyle, options: .new) { [weak self] (_, _) in
      ASPerformBlockOnMainThread {
        self?.adapter.performUpdates(animated: true, completion: nil)
      }
    }
    settledOnlyObserver = Store.provenance.observe(\.settledOnly, options: .new) { [weak self] (_, change) in
      ASPerformBlockOnMainThread {
        guard let value = change.newValue else { return }
        self?.showSettledOnly = value
      }
    }
    paginationCursorObserver = Store.provenance.observe(\.paginationCursor, options: .new) { [weak self] (_, change) in
      guard let value = change.newValue else { return }
      self?.cursor = value.isEmpty ? nil : value
    }
    transactionGroupingObserver = Store.provenance.observe(\.transactionGrouping, options: .new) { [weak self] (_, change) in
      ASPerformBlockOnMainThread {
        guard let value = change.newValue, let grouping = TransactionGroupingEnum(rawValue: value) else { return }
        self?.transactionGrouping = grouping
      }
    }
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForeground, object: nil)
    apiKeyObserver?.invalidate()
    apiKeyObserver = nil
    dateStyleObserver?.invalidate()
    dateStyleObserver = nil
    settledOnlyObserver?.invalidate()
    settledOnlyObserver = nil
    paginationCursorObserver?.invalidate()
    paginationCursorObserver = nil
    transactionGroupingObserver?.invalidate()
    transactionGroupingObserver = nil
  }

  private func configureNavigation() {
    navigationItem.title = "Loading"
    navigationItem.largeTitleDisplayMode = .always
    navigationItem.backBarButtonItem = .dollarsignCircle
    navigationItem.searchController = searchController
  }
}

// MARK: - Actions

extension TransactionsVC {
  @objc
  private func appMovedToForeground() {
    ASPerformBlockOnMainThread {
      self.fetchingTasks()
    }
  }

  @objc
  private func switchDateStyle() {
    switch Store.provenance.appDateStyle {
    case .absolute:
      Store.provenance.appDateStyle = .relative
    case .relative:
      Store.provenance.appDateStyle = .absolute
    }
  }

  @objc
  private func refreshTransactions() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.fetchingTasks()
    }
  }

  private func openDatePicker() {
    let viewController = NavigationController(rootViewController: DatePickerVC(self))
    present(viewController, animated: true)
  }

  private func transactionsUpdates() {
    loading = false
    noTransactions = transactions.isEmpty
    collectionNode.view.refreshControl?.endRefreshing()
    searchController.searchBar.placeholder = preFilteredTransactions.searchBarPlaceholder
    adapter.performUpdates(animated: true, completion: nil)
  }

  private func filterUpdates() {
    filterBarButtonItem.menu = filterMenu
    searchController.searchBar.placeholder = preFilteredTransactions.searchBarPlaceholder
    adapter.performUpdates(animated: true, completion: nil)
  }

  private func fetchingTasks() {
    fetchTransactions()
  }

  private var filterMenu: UIMenu {
    return .transactionsFilter(
      categoryFilter: categoryFilter,
      datesFilter: (sinceDate != nil) || (untilDate != nil),
      groupingFilter: transactionGrouping,
      showSettledOnly: showSettledOnly,
      completion: { (type) in
        switch type {
        case let .category(category):
          self.categoryFilter = category
        case let .grouping(grouping):
          self.transactionGrouping = grouping
        case let .settledOnly(settledOnly):
          self.showSettledOnly = settledOnly
        case .dates:
          self.openDatePicker()
        }
      }
    )
  }

  func fetchTransactions() {
    Up.listTransactions(since: sinceDate, until: untilDate) { (result) in
      switch result {
      case let .success(transactions):
        self.display(transactions)
      case let .failure(error):
        self.display(error)
      }
    }
  }

  private func fetchTransactionsWithCursor() {
    Up.listTransactions(cursor: cursor, since: sinceDate, until: untilDate) { (result) in
      switch result {
      case let .success(transactions):
        self.transactions.append(contentsOf: transactions)
      case let .failure(error):
        self.display(error)
      }
    }
  }

  private func display(_ transactions: [TransactionResource]) {
    transactionsError = ""
    self.transactions = transactions
    if navigationItem.title != "Transactions" {
      navigationItem.title = "Transactions"
    }
    if navigationItem.leftBarButtonItem == nil {
      navigationItem.setLeftBarButton(.dateStyleButtonItem(self, action: #selector(switchDateStyle)), animated: true)
    }
    if navigationItem.rightBarButtonItem == nil {
      navigationItem.setRightBarButton(filterBarButtonItem, animated: true)
    }
  }

  private func display(_ error: AFError) {
    transactionsError = error.underlyingError?.localizedDescription ?? error.localizedDescription
    transactions.removeAll()
    if navigationItem.title != "Error" {
      navigationItem.title = "Error"
    }
    if navigationItem.leftBarButtonItem != nil {
      navigationItem.setLeftBarButton(nil, animated: true)
    }
    if navigationItem.rightBarButtonItem != nil {
      navigationItem.setRightBarButton(nil, animated: true)
    }
  }
}

// MARK: - ListAdapterDataSource

extension TransactionsVC: ListAdapterDataSource {
  func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
    switch transactionGrouping {
    case .all:
      var objects = filteredTransactions.sortedTransactionsModels.diffablesObject
      if loading {
        objects.append(spinToken as ListDiffable)
      }
      return objects
    case .dates, .transactions:
      var objects = filteredTransactions.sortedTransactionsModels.diffablesObject.filter { type(of: $0) == transactionGrouping.valueType! }
      if loading {
        objects.append(spinToken as ListDiffable)
      }
      return objects
    }
  }

  func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
    switch object {
    case spinToken as String:
      return SpinnerSC()
    case is DateHeaderModel:
      return DateHeaderModelSC()
    case is TransactionCellModel:
      return TransactionModelSC(selectionDelegate: self, loadingDelegate: self)
    default:
      fatalError("Unknown object")
    }
  }

  func emptyView(for listAdapter: ListAdapter) -> UIView? {
    if filteredTransactions.isEmpty && transactionsError.isEmpty {
      if transactions.isEmpty && !noTransactions {
        return .loading(frame: collectionNode.bounds, contentType: .transactions)
      } else {
        return .noContent(frame: collectionNode.bounds, type: .transactions)
      }
    } else {
      if !transactionsError.isEmpty {
        return .error(frame: collectionNode.bounds, text: transactionsError)
      } else {
        return nil
      }
    }
  }
}

// MARK: - SelectionDelegate

extension TransactionsVC: SelectionDelegate {
  func didSelectItem(at indexPath: IndexPath) {
    switch transactionGrouping.valueType {
    case is TransactionCellModel.Type:
      let transaction = filteredTransactions.sortedTransactionsModels.supplementaryObject.filter { type(of: $0) == TransactionResource.self }.transactionResources[indexPath.section]
      let viewController = TransactionDetailVC(transaction: transaction)
      navigationController?.pushViewController(viewController, animated: true)
    case is DateHeaderModel.Type:
      break
    case nil:
      if let transaction = filteredTransactions.sortedTransactionsModels.supplementaryObject[indexPath.section] as? TransactionResource {
        let viewController = TransactionDetailVC(transaction: transaction)
        navigationController?.pushViewController(viewController, animated: true)
      }
    default:
      fatalError("Unknown transaction grouping value type")
    }
  }
}

// MARK: - LoadingDelegate

extension TransactionsVC: LoadingDelegate {
  func startLoading() {
    if cursor != nil && !loading && !searchController.isActive && !searchController.searchBar.searchTextField.hasText {
      loading = true
      adapter.performUpdates(animated: true, completion: nil)
      fetchTransactionsWithCursor()
    }
  }
}

// MARK: - UISearchBarDelegate

extension TransactionsVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    adapter.performUpdates(animated: true, completion: nil)
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if searchBar.searchTextField.hasText {
      searchBar.clear()
      adapter.performUpdates(animated: true, completion: nil)
    }
  }
}
