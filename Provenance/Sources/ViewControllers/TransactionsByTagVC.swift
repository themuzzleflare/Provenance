import UIKit
import AsyncDisplayKit
import IGListKit
import Alamofire

final class TransactionsByTagVC: ASViewController, UIProtocol {
  // MARK: - Properties

  var state: UIState = .initialLoad {
    didSet {
      if oldValue != state {
        UIUpdates.updateUI(state: state, contentType: .transactions, collection: .tableNode(tableNode))
      }
    }
  }

  private var tag: TagResource

  private lazy var searchController = UISearchController(self)

  private let tableNode = ASTableNode(style: .plain)

  private var dateStyleObserver: NSKeyValueObservation?

  private var noTransactions: Bool = false

  private var transactions = [TransactionResource]() {
    didSet {
      noTransactions = transactions.isEmpty
      if transactions.isEmpty {
        navigationController?.popViewController(animated: true)
      } else {
        tableNode.view.refreshControl?.endRefreshing()
        applySnapshot()
        searchController.searchBar.placeholder = transactions.searchBarPlaceholder
      }
    }
  }

  private var transactionsError = String()

  private var oldTransactionCellModels = [ListDiffable]()

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
    configureSelf()
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

extension TransactionsByTagVC {
  private func configureSelf() {
    title = "Transactions by Tag"
    definesPresentationContext = true
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
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
  }

  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.refreshControl = UIRefreshControl(self, action: #selector(refreshTransactions))
  }
}

// MARK: - Actions

extension TransactionsByTagVC {
  @objc
  private func appMovedToForeground() {
    ASPerformBlockOnMainThread {
      self.fetchTransactions()
    }
  }

  @objc
  private func refreshTransactions() {
    fetchTransactions()
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

  func fetchTransactions() {
    Up.listTransactions(filterBy: tag) { (result) in
      switch result {
      case let .success(transactions):
        self.display(transactions)
      case let .failure(error):
        self.display(error)
      }
    }
  }

  private func display(_ transactions: [TransactionResource]) {
    transactionsError = ""
    self.transactions = transactions
    if navigationItem.title != tag.id {
      navigationItem.title = tag.id
    }
    if navigationItem.rightBarButtonItem == nil {
      navigationItem.setRightBarButton(editButtonItem, animated: true)
    }
  }

  private func display(_ error: AFError) {
    transactionsError = error.underlyingError?.localizedDescription ?? error.localizedDescription
    transactions.removeAll()
    if navigationItem.title != "Error" {
      navigationItem.title = "Error"
    }
    if navigationItem.rightBarButtonItem != nil {
      navigationItem.setRightBarButton(nil, animated: true)
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
    return {
      TransactionCellNode(model: transaction.cellModel, contextMenu: false, selection: false)
    }
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    switch editingStyle {
    case .delete:
      let transaction = filteredTransactions[indexPath.row]
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
    return isEditing ? nil : UIContextMenuConfiguration(elements: [
      .copyTransactionDescription(transaction: transaction),
      .copyTransactionCreationDate(transaction: transaction),
      .copyTransactionAmount(transaction: transaction),
      .removeTagFromTransaction(self, removing: tag, from: transaction)
    ])
  }
}

// MARK: - UISearchBarDelegate

extension TransactionsByTagVC: UISearchBarDelegate {
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
