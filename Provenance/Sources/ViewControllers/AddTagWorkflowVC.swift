import UIKit
import IGListKit
import AsyncDisplayKit

final class AddTagWorkflowVC: ASViewController {
  // MARK: - Properties

  private lazy var searchController = UISearchController(self)

  private lazy var tableRefreshControl = UIRefreshControl(self, selector: #selector(refreshTransactions))

  private let tableNode = ASTableNode(style: .grouped)

  private var dateStyleObserver: NSKeyValueObservation?

  private var noTransactions: Bool = false

  private var transactions = [TransactionResource]() {
    didSet {
      noTransactions = transactions.isEmpty
      applySnapshot()
      tableNode.view.refreshControl?.endRefreshing()
      searchController.searchBar.placeholder = "Search \(transactions.count.description) \(transactions.count == 1 ? "Transaction" : "Transactions")"
    }
  }

  private var transactionsError = String()

  private var oldFilteredTransactions = [TransactionResource]()

  private var filteredTransactions: [TransactionResource] {
    return transactions.filtered(searchBar: searchController.searchBar)
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
    configureProperties()
    configureNavigation()
    configureTableNode()
    applySnapshot(override: true)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchTransactions()
  }
}

// MARK: - Configuration

private extension AddTagWorkflowVC {
  private func configureProperties() {
    title = "Transaction Selection"
    definesPresentationContext = true
  }

  private func configureObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appMovedToForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
    dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { [weak self] (_, change) in
      guard let weakSelf = self, let value = change.newValue else { return }
      DispatchQueue.main.async {
        weakSelf.fetchTransactions()
      }
    }
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self)
    dateStyleObserver?.invalidate()
    dateStyleObserver = nil
  }

  private func configureNavigation() {
    navigationItem.title = "Loading"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
    navigationItem.backButtonDisplayMode = .minimal
  }

  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.refreshControl = tableRefreshControl
  }
}

// MARK: - Actions

private extension AddTagWorkflowVC {
  @objc private func appMovedToForeground() {
    fetchTransactions()
  }

  @objc private func refreshTransactions() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
      fetchTransactions()
    }
  }

  @objc private func closeWorkflow() {
    navigationController?.dismiss(animated: true)
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
          tableNode.view.backgroundView = .loadingView(frame: tableNode.bounds)
        } else {
          tableNode.view.backgroundView = .noContentView(frame: tableNode.bounds, type: .transactions)
        }
      } else {
        if !transactionsError.isEmpty {
          tableNode.view.backgroundView = .errorView(frame: tableNode.bounds, text: transactionsError)
        } else {
          if tableNode.view.backgroundView != nil { tableNode.view.backgroundView = nil }
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
    transactionsError = ""
    self.transactions = transactions
    if navigationItem.title != "Select Transaction" {
      navigationItem.title = "Select Transaction"
    }
  }

  private func display(_ error: NetworkError) {
    transactionsError = error.description
    transactions = []
    if navigationItem.title != "Error" {
      navigationItem.title = "Error"
    }
  }
}

// MARK: - ASTableDataSource

extension AddTagWorkflowVC: ASTableDataSource {
  func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
    return filteredTransactions.count
  }

  func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
    let node = TransactionCellNode(transaction: filteredTransactions[indexPath.row])
    return {
      node
    }
  }
}

// MARK: - ASTableDelegate

extension AddTagWorkflowVC: ASTableDelegate {
  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    tableNode.deselectRow(at: indexPath, animated: true)
    let transaction = filteredTransactions[indexPath.row]
    navigationController?.pushViewController(AddTagWorkflowTwoVC(transaction: transaction), animated: true)
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

extension AddTagWorkflowVC: UISearchBarDelegate {
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
