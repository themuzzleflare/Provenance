import IGListKit
import AsyncDisplayKit
import Alamofire

final class TransactionsVC: ASViewController {
  // MARK: - Properties
  
  private lazy var filterBarButtonItem = UIBarButtonItem(image: .sliderHorizontal3, menu: filterMenu)
  
  private lazy var searchController = UISearchController(self)
  
  private lazy var adapter: ListAdapter = {
    return ListAdapter(updater: ListAdapterUpdater(), viewController: self)
  }()
  
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
  
  private var transactionGrouping: TransactionGroupingEnum = ProvenanceApp.userDefaults.appTransactionGrouping {
    didSet {
      if ProvenanceApp.userDefaults.transactionGrouping != transactionGrouping.rawValue {
        ProvenanceApp.userDefaults.transactionGrouping = transactionGrouping.rawValue
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
      return (!showSettledOnly || transaction.attributes.status.isSettled) && (categoryFilter == .all || categoryFilter.rawValue == transaction.relationships.category.data?.id)
    }
  }
  
  private var categoryFilter: TransactionCategory = ProvenanceApp.userDefaults.appSelectedCategory {
    didSet {
      if ProvenanceApp.userDefaults.selectedCategory != categoryFilter.rawValue {
        ProvenanceApp.userDefaults.selectedCategory = categoryFilter.rawValue
      }
      filterUpdates()
    }
  }
  
  private var showSettledOnly: Bool = ProvenanceApp.userDefaults.settledOnly {
    didSet {
      if ProvenanceApp.userDefaults.settledOnly != showSettledOnly {
        ProvenanceApp.userDefaults.settledOnly = showSettledOnly
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
    NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: .willEnterForegroundNotification, object: nil)
    apiKeyObserver = ProvenanceApp.userDefaults.observe(\.apiKey, options: .new) { [weak self] (_, _) in
      guard let weakSelf = self else { return }
      weakSelf.fetchingTasks()
    }
    dateStyleObserver = ProvenanceApp.userDefaults.observe(\.dateStyle, options: .new) { [weak self] (_, _) in
      guard let weakSelf = self else { return }
      weakSelf.adapter.performUpdates(animated: true)
    }
    settledOnlyObserver = ProvenanceApp.userDefaults.observe(\.settledOnly, options: .new) { [weak self] (_, change) in
      guard let weakSelf = self, let value = change.newValue else { return }
      weakSelf.showSettledOnly = value
    }
    paginationCursorObserver = ProvenanceApp.userDefaults.observe(\.paginationCursor, options: .new) { [weak self] (_, change) in
      guard let weakSelf = self, let value = change.newValue else { return }
      weakSelf.cursor = value.isEmpty ? nil : value
    }
    transactionGroupingObserver = ProvenanceApp.userDefaults.observe(\.transactionGrouping, options: .new) { [weak self] (_, change) in
      guard let weakSelf = self, let value = change.newValue, let grouping = TransactionGroupingEnum(rawValue: value) else { return }
      weakSelf.transactionGrouping = grouping
    }
  }
  
  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForegroundNotification, object: nil)
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
  @objc private func appMovedToForeground() {
    fetchingTasks()
  }
  
  @objc private func switchDateStyle() {
    switch ProvenanceApp.userDefaults.appDateStyle {
    case .absolute:
      ProvenanceApp.userDefaults.appDateStyle = .relative
    case .relative:
      ProvenanceApp.userDefaults.appDateStyle = .absolute
    }
  }
  
  @objc private func refreshTransactions() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.fetchingTasks()
    }
  }
  
  private func transactionsUpdates() {
    loading = false
    noTransactions = transactions.isEmpty
    adapter.performUpdates(animated: true)
    collectionNode.view.refreshControl?.endRefreshing()
    searchController.searchBar.placeholder = preFilteredTransactions.searchBarPlaceholder
  }
  
  private func filterUpdates() {
    filterBarButtonItem.menu = filterMenu
    searchController.searchBar.placeholder = preFilteredTransactions.searchBarPlaceholder
    adapter.performUpdates(animated: true)
  }
  
  private func fetchingTasks() {
    fetchTransactions()
  }
  
  private var filterMenu: UIMenu {
    return .transactionsFilterMenu(
      categoryFilter: categoryFilter,
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
        }
      }
    )
  }
  
  private func fetchTransactions() {
    UpFacade.listTransactions { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(transactions):
          self.display(transactions)
        case let .failure(error):
          self.display(error)
        }
      }
    }
  }
  
  private func fetchTransactionsWithCursor() {
    UpFacade.listTransactions(cursor: cursor) { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(transactions):
          self.transactions.append(contentsOf: transactions)
        case let .failure(error):
          self.display(error)
        }
      }
    }
  }
  
  private func display(_ transactions: [TransactionResource]) {
    transactionsError = .emptyString
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
    transactionsError = error.errorDescription ?? error.localizedDescription
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
    guard transactionGrouping != .all else {
      var objects = filteredTransactions.sortedTransactionModels.sortedMixedModel
      if loading {
        objects.append(spinToken as ListDiffable)
      }
      return objects
    }
    var objects = filteredTransactions.sortedTransactionModels.sortedMixedModel.filter { type(of: $0) == transactionGrouping.valueType! }
    if loading {
      objects.append(spinToken as ListDiffable)
    }
    return objects
  }
  
  func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
    if let obj = object as? String, obj == spinToken {
      return SpinnerSC()
    } else {
      switch object {
      case is SortedSectionModel:
        return SectionModelSC()
      default:
        return ItemModelSC(self, self)
      }
    }
  }
  
  func emptyView(for listAdapter: ListAdapter) -> UIView? {
    if filteredTransactions.isEmpty && transactionsError.isEmpty {
      if transactions.isEmpty && !noTransactions {
        return .loadingView(frame: collectionNode.bounds, contentType: .transactions)
      } else {
        return .noContentView(frame: collectionNode.bounds, type: .transactions)
      }
    } else {
      if !transactionsError.isEmpty {
        return .errorView(frame: collectionNode.bounds, text: transactionsError)
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
      let transaction = filteredTransactions.sortedTransactionCoreModels.sortedMixedCoreModel.filter { type(of: $0) == TransactionResource.self }.transactionResources[indexPath.section]
      let viewController = TransactionDetailVC(transaction: transaction)
      navigationController?.pushViewController(viewController, animated: true)
    default:
      if let transaction = filteredTransactions.sortedTransactionCoreModels.sortedMixedCoreModel[indexPath.section] as? TransactionResource {
        let viewController = TransactionDetailVC(transaction: transaction)
        navigationController?.pushViewController(viewController, animated: true)
      }
    }
  }
}

// MARK: - LoadingDelegate

extension TransactionsVC: LoadingDelegate {
  func startLoading() {
    if cursor != nil && !loading && !searchController.isActive && !searchController.searchBar.searchTextField.hasText {
      loading = true
      adapter.performUpdates(animated: true)
      DispatchQueue.global(qos: .default).async {
        sleep(2)
        self.fetchTransactionsWithCursor()
      }
    }
  }
}

// MARK: - UISearchBarDelegate

extension TransactionsVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    adapter.performUpdates(animated: true)
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if searchBar.searchTextField.hasText {
      searchBar.clear()
      adapter.performUpdates(animated: true)
    }
  }
}
