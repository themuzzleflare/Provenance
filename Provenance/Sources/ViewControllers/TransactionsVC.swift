import IGListKit
import AsyncDisplayKit
import Alamofire

final class TransactionsVC: ASViewController {
    // MARK: - Properties
  
  private lazy var filterBarButtonItem = UIBarButtonItem(image: .sliderHorizontal3, menu: filterMenu)
  
  private lazy var searchController = UISearchController(self)
  
  private let tableNode = ASTableNode(style: .grouped)
  
  private var apiKeyObserver: NSKeyValueObservation?
  
  private var dateStyleObserver: NSKeyValueObservation?
  
  private var noTransactions: Bool = false
  
  private var transactionsError = String()
  
  private var transactions = [TransactionResource]() {
    didSet {
      transactionsUpdates()
    }
  }
  
  private var oldFilteredTransactions = [TransactionResource]()
  
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
    super.init(node: tableNode)
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
    configureTableNode()
    configureSelf()
    configureNavigation()
    applySnapshot(override: true)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchingTasks()
  }
}

  // MARK: - Configuration

extension TransactionsVC {
  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.refreshControl = UIRefreshControl(self, action: #selector(refreshTransactions))
  }
  
  private func configureSelf() {
    title = "Transactions"
    definesPresentationContext = true
  }
  
  private func configureObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appMovedToForeground),
      name: .willEnterForegroundNotification,
      object: nil
    )
    apiKeyObserver = ProvenanceApp.userDefaults.observe(\.apiKey, options: .new) { [weak self] (_, _) in
      guard let weakSelf = self else { return }
      DispatchQueue.main.async {
        weakSelf.fetchingTasks()
      }
    }
    dateStyleObserver = ProvenanceApp.userDefaults.observe(\.dateStyle, options: .new) { [weak self] (_, _) in
      guard let weakSelf = self else { return }
      DispatchQueue.main.async {
        weakSelf.tableNode.reloadData()
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
    navigationItem.backBarButtonItem = UIBarButtonItem(image: .dollarsignCircle)
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
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
      fetchingTasks()
    }
  }
  
  private func transactionsUpdates() {
    noTransactions = transactions.isEmpty
    applySnapshot()
    tableNode.view.refreshControl?.endRefreshing()
    searchController.searchBar.placeholder = preFilteredTransactions.searchBarPlaceholder
  }
  
  private func filterUpdates() {
    filterBarButtonItem.menu = filterMenu
    searchController.searchBar.placeholder = preFilteredTransactions.searchBarPlaceholder
    applySnapshot()
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
  
  private func applySnapshot(override: Bool = false) {
    let result = ListDiffPaths(
      fromSection: 0,
      toSection: 0,
      oldArray: oldFilteredTransactions,
      newArray: filteredTransactions,
      option: .equality
    ).forBatchUpdates()
    if result.hasChanges || override || !transactionsError.isEmpty || noTransactions {
      if filteredTransactions.isEmpty && transactionsError.isEmpty {
        if transactions.isEmpty && !noTransactions {
          tableNode.view.backgroundView = .loadingView(frame: tableNode.bounds, contentType: .transactions)
        } else {
          tableNode.view.backgroundView = .noContentView(frame: tableNode.bounds, type: .transactions)
        }
      } else {
        if !transactionsError.isEmpty {
          tableNode.view.backgroundView = .errorView(frame: tableNode.bounds, text: transactionsError)
        } else {
          if tableNode.view.backgroundView != nil {
            tableNode.view.backgroundView = nil
          }
        }
      }
      let batchUpdates = { [self] in
        tableNode.deleteRows(at: result.deletes, with: .fade)
        tableNode.insertRows(at: result.inserts, with: .fade)
        result.moves.forEach { tableNode.moveRow(at: $0.from, to: $0.to) }
        oldFilteredTransactions = filteredTransactions
      }
      tableNode.performBatchUpdates(batchUpdates)
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
      navigationItem.setLeftBarButtonItems([.dateStyleButtonItem(self, selector: #selector(switchDateStyle)), filterBarButtonItem], animated: true)
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

  // MARK: - ASTableDataSource

extension TransactionsVC: ASTableDataSource {
  func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
    return filteredTransactions.count
  }
  
  func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
    let transaction = filteredTransactions[indexPath.row]
    let node = TransactionCellNode(transaction: transaction)
    return {
      node
    }
  }
}

  // MARK: - ASTableDelegate

extension TransactionsVC: ASTableDelegate {
  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    let transaction = filteredTransactions[indexPath.row]
    let viewController = TransactionDetailVC(transaction: transaction)
    tableNode.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(viewController, animated: true)
  }
  
  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let transaction = filteredTransactions[indexPath.row]
    return UIContextMenuConfiguration(elements: [
      .copyTransactionDescription(transaction: transaction),
      .copyTransactionCreationDate(transaction: transaction),
      .copyTransactionAmount(transaction: transaction)
    ])
  }
}

  // MARK: - UISearchBarDelegate

extension TransactionsVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    applySnapshot()
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if !searchBar.text!.isEmpty {
      searchBar.clear()
      applySnapshot()
    }
  }
}
