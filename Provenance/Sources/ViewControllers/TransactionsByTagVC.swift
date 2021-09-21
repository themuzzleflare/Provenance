import UIKit
import NotificationBannerSwift
import IGListKit
import AsyncDisplayKit

final class TransactionsByTagVC: ASViewController {
    // MARK: - Properties
  
  private var tag: TagResource
  
  private lazy var searchController = UISearchController(self)
  
  private lazy var tableRefreshControl = UIRefreshControl(self, selector: #selector(refreshTransactions))
  
  private let tableNode = ASTableNode(style: .grouped)
  
  private var dateStyleObserver: NSKeyValueObservation?
  
  private var noTransactions: Bool = false
  
  private var transactions = [TransactionResource]() {
    didSet {
      noTransactions = transactions.isEmpty
      if transactions.isEmpty {
        navigationController?.popViewController(animated: true)
      } else {
        applySnapshot()
        tableNode.view.refreshControl?.endRefreshing()
        searchController.searchBar.placeholder = "Search \(transactions.count.description) \(transactions.count == 1 ? "Transaction" : "Transactions")"
      }
    }
  }
  
  private var transactionsError = String()
  
  private var oldFilteredTransactions = [TransactionResource]()
  
  private var filteredTransactions: [TransactionResource] {
    return transactions.filtered(searchBar: searchController.searchBar)
  }
  
    // MARK: - Life Cycle
  
  init(tag: TagResource) {
    self.tag = tag
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
  
  override func setEditing(_ editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    tableNode.view.setEditing(editing, animated: animated)
  }
}

  // MARK: - Configuration

private extension TransactionsByTagVC {
  private func configureProperties() {
    title = "Transactions by Tag"
    definesPresentationContext = true
  }
  
  private func configureObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { [weak self] (_, _) in
      guard let weakSelf = self else { return }
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
    navigationItem.backBarButtonItem = UIBarButtonItem(image: .dollarsignCircle)
    navigationItem.rightBarButtonItem = editButtonItem
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
  }
  
  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.refreshControl = tableRefreshControl
  }
}

  // MARK: - Actions

extension TransactionsByTagVC {
  @objc private func appMovedToForeground() {
    fetchTransactions()
  }
  
  @objc private func refreshTransactions() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
      fetchTransactions()
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
          tableNode.view.backgroundView = .loadingView(frame: tableNode.bounds)
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
  
  func fetchTransactions() {
    UpFacade.listTransactions(filterBy: tag) { [self] result in
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
    if navigationItem.title != tag.id {
      navigationItem.title = tag.id
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

extension TransactionsByTagVC: ASTableDataSource {
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
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    let transaction = filteredTransactions[indexPath.row]
    switch editingStyle {
    case .delete:
      let alertController = UIAlertController.removeTagFromTransaction(self, removing: tag, from: transaction)
      present(alertController, animated: true)
    default:
      break
    }
  }
}

  // MARK: - ASTableDelegate

extension TransactionsByTagVC: ASTableDelegate {
  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    let transaction = filteredTransactions[indexPath.row]
    let viewController = TransactionDetailVC(transaction: transaction)
    tableNode.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(viewController, animated: true)
  }
  
  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    return .delete
  }
  
  func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
    return "Remove"
  }
  
  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let transaction = filteredTransactions[indexPath.row]
    switch isEditing {
    case true:
      return nil
    case false:
      return UIContextMenuConfiguration(elements: [
        .copyTransactionDescription(transaction: transaction),
        .copyTransactionCreationDate(transaction: transaction),
        .copyTransactionAmount(transaction: transaction),
        .removeTagFromTransaction(self, removing: tag, from: transaction)
      ])
    }
  }
}

  // MARK: - UISearchBarDelegate

extension TransactionsByTagVC: UISearchBarDelegate {
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
