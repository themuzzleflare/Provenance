import UIKit
import AsyncDisplayKit
import IGListKit
import MarqueeLabel
import Alamofire

final class TransactionsByAccountVC: ASViewController, UIProtocol {
  // MARK: - Properties

  var state: UIState = .initialLoad {
    didSet {
      if oldValue != state {
        UIUpdates.updateUI(state: state, contentType: .transactions, collection: .tableNode(tableNode))
      }
    }
  }

  private var account: AccountResource {
    didSet {
      accountBalance = account.attributes.balance.value
    }
  }

  private var accountBalance = String() {
    didSet {
      if oldValue != accountBalance {
        setTableHeaderView()
      }
    }
  }

  private lazy var searchController = UISearchController(self)

  private let tableNode = ASTableNode(style: .plain)

  private var dateStyleObserver: NSKeyValueObservation?

  private var noTransactions: Bool = false

  private var transactions = [TransactionResource]() {
    didSet {
      transactionsUpdates()
    }
  }

  private var transactionsError = String()

  private var oldTransactionCellModels = [ListDiffable]()

  private var filteredTransactions: [TransactionResource] {
    return transactions.filtered(searchBar: searchController.searchBar)
  }

  // MARK: - Life Cycle

  init(account: AccountResource) {
    self.account = account
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
    configureSelf()
    configureObservers()
    configureNavigation()
    configureTableNode()
    applySnapshot(override: true)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchingTasks()
  }
}

// MARK: - Configuration

extension TransactionsByAccountVC {
  private func configureSelf() {
    title = "Transactions by Account"
    definesPresentationContext = false
  }

  private func configureObservers() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(appMovedToForeground),
                                           name: .willEnterForeground,
                                           object: nil)
    dateStyleObserver = Store.provenance.observe(\.dateStyle, options: .new) { [weak self] (_, _) in
      ASPerformBlockOnMainThread {
        self?.applySnapshot()
      }
    }
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForeground, object: nil)
    dateStyleObserver?.invalidate()
    dateStyleObserver = nil
  }

  private func configureNavigation() {
    navigationItem.title = "Loading"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.backBarButtonItem = .dollarsignCircle
    navigationItem.rightBarButtonItem = .accountInfo(self, action: #selector(openAccountInfo))
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
  }

  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.refreshControl = UIRefreshControl(self, action: #selector(refreshData))
  }
}

// MARK: - Actions

extension TransactionsByAccountVC {
  @objc
  private func appMovedToForeground() {
    ASPerformBlockOnMainThread {
      self.fetchingTasks()
    }
  }

  @objc
  private func openAccountInfo() {
    let viewController = NavigationController(rootViewController: AccountDetailVC(account: account, transaction: transactions.first))
    present(viewController, animated: true)
  }

  @objc
  private func refreshData() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.fetchingTasks()
    }
  }

  private func setTableHeaderView() {
    tableNode.view.tableHeaderView = .accountTransactionsHeader(frame: tableNode.bounds, account: account)
  }

  private func fetchingTasks() {
    fetchAccount()
    fetchTransactions()
  }

  private func transactionsUpdates() {
    noTransactions = transactions.isEmpty
    tableNode.view.refreshControl?.endRefreshing()
    applySnapshot()
    searchController.searchBar.placeholder = transactions.searchBarPlaceholder
  }

  private func applySnapshot(override: Bool = false) {
    UIUpdates.applySnapshot(oldArray: &oldTransactionCellModels,
                            newArray: filteredTransactions.cellModels,
                            override: override,
                            state: &state,
                            contents: transactions,
                            filteredContents: filteredTransactions,
                            noContent: noTransactions,
                            error: transactionsError,
                            contentType: .transactions,
                            collection: .tableNode(tableNode))
  }

  private func fetchAccount() {
    Up.retrieveAccount(for: account) { (result) in
      switch result {
      case let .success(account):
        self.display(account)
      case .failure:
        break
      }
    }
  }

  private func fetchTransactions() {
    Up.listTransactions(filterBy: account) { (result) in
      switch result {
      case let .success(transactions):
        self.display(transactions)
      case let .failure(error):
        self.display(error)
      }
    }
  }

  private func display(_ account: AccountResource) {
    self.account = account
  }

  private func display(_ transactions: [TransactionResource]) {
    transactionsError = ""
    self.transactions = transactions
    if navigationItem.title != account.attributes.displayName {
      navigationItem.title = account.attributes.displayName
      navigationItem.titleView = MarqueeLabel(text: account.attributes.displayName)
    }
  }

  private func display(_ error: AFError) {
    transactionsError = error.underlyingError?.localizedDescription ?? error.localizedDescription
    transactions.removeAll()
    if navigationItem.title != "Error" {
      navigationItem.title = "Error"
    }
  }
}

// MARK: - ASTableDataSource

extension TransactionsByAccountVC: ASTableDataSource {
  func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
    return filteredTransactions.count
  }

  func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
    let transaction = filteredTransactions[indexPath.row]
    return {
      TransactionCellNode(model: transaction.cellModel, selection: false)
    }
  }
}

// MARK: - ASTableDelegate

extension TransactionsByAccountVC: ASTableDelegate {
  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    let transaction = filteredTransactions[indexPath.row]
    let viewController = TransactionDetailVC(transaction: transaction)
    tableNode.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(viewController, animated: true)
  }
}

// MARK: - UISearchBarDelegate

extension TransactionsByAccountVC: UISearchBarDelegate {
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
