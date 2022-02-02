import UIKit
import IGListKit
import AsyncDisplayKit
import MarqueeLabel
import Alamofire

final class TransactionsByAccountVC: ASViewController {
  // MARK: - Properties

  private var account: AccountResource {
    didSet {
      if !searchController.isActive && !searchController.searchBar.searchTextField.hasText {
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

  private var oldTransactionCellModels = [TransactionCellModel]()

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
    print("\(#function) \(String(describing: type(of: self)))")
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureObservers()
    configureSelf()
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
                                           name: .willEnterForegroundNotification,
                                           object: nil)
    dateStyleObserver = Store.provenance.observe(\.dateStyle, options: .new) { [weak self] (_, _) in
      self?.applySnapshot()
    }
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForegroundNotification, object: nil)
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
    fetchingTasks()
  }

  @objc
  private func openAccountInfo() {
    let viewController = NavigationController(rootViewController: AccountDetailVC(account: account, transaction: transactions.first))
    present(viewController, animated: true)
  }

  @objc
  private func refreshData() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.fetchingTasks()
    }
  }

  private func setTableHeaderView() {
    DispatchQueue.main.async { [self] in
      tableNode.view.tableHeaderView = .accountTransactionsHeaderView(frame: tableNode.bounds, account: account)
    }
  }

  private func fetchingTasks() {
    fetchAccount()
    fetchTransactions()
  }

  private func transactionsUpdates() {
    noTransactions = transactions.isEmpty
    applySnapshot()
    tableNode.view.refreshControl?.endRefreshing()
    searchController.searchBar.placeholder = transactions.searchBarPlaceholder
  }

  private func applySnapshot(override: Bool = false) {
    DispatchQueue.main.async { [self] in
      let result = ListDiffPaths(
        fromSection: 0,
        toSection: 0,
        oldArray: oldTransactionCellModels,
        newArray: filteredTransactions.transactionCellModels,
        option: .equality
      ).forBatchUpdates()

      if result.hasChanges || override || !transactionsError.isEmpty || noTransactions || searchController.searchBar.searchTextField.hasText {
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

        let batchUpdates = {
          tableNode.deleteRows(at: result.deletes, with: .fade)
          tableNode.insertRows(at: result.inserts, with: .fade)
          result.moves.forEach { tableNode.moveRow(at: $0.from, to: $0.to) }
          oldTransactionCellModels = filteredTransactions.transactionCellModels
        }

        tableNode.performBatchUpdates(batchUpdates)
      }
    }
  }

  private func fetchAccount() {
    Up.retrieveAccount(for: account) { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(account):
          self.display(account)
        case .failure:
          break
        }
      }
    }
  }

  private func fetchTransactions() {
    Up.listTransactions(filterBy: account) { (result) in
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
    let node = TransactionCellNode(transaction: transaction, selection: false)
    return {
      node
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
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    DispatchQueue.main.async { [self] in
      tableNode.view.tableHeaderView = nil
    }
  }

  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    if !searchBar.searchTextField.hasText {
      setTableHeaderView()
    }
  }

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    applySnapshot()
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if searchBar.searchTextField.hasText {
      searchBar.clear()
      setTableHeaderView()
      applySnapshot()
    }
  }
}
