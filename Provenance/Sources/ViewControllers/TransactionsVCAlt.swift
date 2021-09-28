import IGListKit
import AsyncDisplayKit
import Alamofire

final class TransactionsVCAlt: ASViewController {
    // MARK: - Properties
  
  private lazy var filterBarButtonItem = UIBarButtonItem(image: .sliderHorizontal3, menu: filterMenu)
  
  private lazy var searchController = UISearchController(self)
  
  private lazy var adapter: ListAdapter = {
    return ListAdapter(updater: ListAdapterUpdater(), viewController: self)
  }()
  
  private let collectionNode = ASCollectionNode(collectionViewLayout: .sectionHeadersPinned)
  
  private var apiKeyObserver: NSKeyValueObservation?
  
  private var dateStyleObserver: NSKeyValueObservation?
  
  private var noTransactions: Bool = false
  
  private var transactionsError = String()
  
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
      (!showSettledOnly || transaction.attributes.status.isSettled) && (filter == .all || filter.rawValue == transaction.relationships.category.data?.id)
    }
  }
  
  private var filter: CategoryFilter = .all {
    didSet {
      filterUpdates()
    }
  }
  
  private var showSettledOnly: Bool = false {
    didSet {
      filterUpdates()
    }
  }
  
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
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchingTasks()
  }
}

  // MARK: - Configuration

extension TransactionsVCAlt {
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
      DispatchQueue.main.async {
        weakSelf.fetchingTasks()
      }
    }
    dateStyleObserver = ProvenanceApp.userDefaults.observe(\.dateStyle, options: .new) { [weak self] (_, _) in
      guard let weakSelf = self else { return }
      DispatchQueue.main.async {
        weakSelf.adapter.performUpdates(animated: true)
      }
    }
  }
  
  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForegroundNotification, object: nil)
    apiKeyObserver?.invalidate()
    apiKeyObserver = nil
    dateStyleObserver?.invalidate()
    dateStyleObserver = nil
  }
  
  private func configureNavigation() {
    navigationItem.title = "Loading"
    navigationItem.largeTitleDisplayMode = .always
    navigationItem.backBarButtonItem = .dollarsignCircle
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
  }
}

  // MARK: - Actions

extension TransactionsVCAlt {
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
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
      fetchingTasks()
    }
  }
  
  private func transactionsUpdates() {
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
    return .transactionsFilterMenu(filter: filter, showSettledOnly: showSettledOnly) { (type) in
      switch type {
      case let .category(category):
        self.filter = category
      case let .settledOnly(settledOnly):
        self.showSettledOnly = settledOnly
      }
    }
  }
  
  private func fetchTransactions() {
    UpFacade.listTransactions { [self] (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(transactions):
          display(transactions)
        case let .failure(error):
          display(error)
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
    if navigationItem.leftBarButtonItems == nil {
      navigationItem.setLeftBarButtonItems([.dateStyleButtonItem(self, action: #selector(switchDateStyle)), filterBarButtonItem], animated: true)
    }
  }
  
  private func display(_ error: AFError) {
    transactionsError = error.errorDescription ?? error.localizedDescription
    transactions = []
    if navigationItem.title != "Error" {
      navigationItem.title = "Error"
    }
    if navigationItem.leftBarButtonItems != nil {
      navigationItem.setLeftBarButtonItems(nil, animated: true)
    }
  }
}

  // MARK: - ListAdapterDataSource

extension TransactionsVCAlt: ListAdapterDataSource {
  func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
    return filteredTransactions.sortedTransactionModels
  }
  
  func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
    return TransactionsSC(self)
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

extension TransactionsVCAlt: SelectionDelegate {
  func didSelectItem(at indexPath: IndexPath) {
    let transaction = filteredTransactions.sortedTransactionCoreModels[indexPath.section].transactions[indexPath.row]
    let viewController = TransactionDetailVC(transaction: transaction)
    navigationController?.pushViewController(viewController, animated: true)
  }
}

  // MARK: - UISearchBarDelegate

extension TransactionsVCAlt: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    adapter.performUpdates(animated: true)
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if !searchBar.text!.isEmpty {
      searchBar.clear()
      adapter.performUpdates(animated: true)
    }
  }
}
