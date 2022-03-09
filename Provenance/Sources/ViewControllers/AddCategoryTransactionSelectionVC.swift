import UIKit
import AsyncDisplayKit
import IGListKit
import Alamofire
import MBProgressHUD
import NotificationBannerSwift
import BonMot

final class AddCategoryTransactionSelectionVC: ASViewController, UIProtocol {
  // MARK: - Properties

  var state: UIState = .initialLoad {
    didSet {
      if oldValue != state {
        UIUpdates.updateUI(state: state, contentType: .transactions, collection: .tableNode(tableNode))
      }
    }
  }

  private var category: CategoryResource?

  private lazy var searchController = UISearchController(self)

  private let tableNode = ASTableNode(style: .plain)

  private var dateStyleObserver: NSKeyValueObservation?

  private var noTransactions: Bool = false

  private var transactions = [TransactionResource]() {
    didSet {
      noTransactions = transactions.isEmpty
      tableNode.view.refreshControl?.endRefreshing()
      applySnapshot()
      searchController.searchBar.placeholder = preFilteredTransactions.searchBarPlaceholder
    }
  }

  private var transactionsError = String()

  private var oldTransactionCellModels = [ListDiffable]()

  private var preFilteredTransactions: [TransactionResource] {
    return transactions.filter { (transaction) in
      return transaction.attributes.isCategorizable
    }
  }

  private var filteredTransactions: [TransactionResource] {
    return preFilteredTransactions.filtered(searchBar: searchController.searchBar)
  }

  // MARK: - Life Cycle

  init(category: CategoryResource? = nil) {
    self.category = category
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
    fetchTransactions()
  }
}

// MARK: - Configuration

extension AddCategoryTransactionSelectionVC {
  private func configureSelf() {
    title = "Transaction Selection"
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
    navigationItem.leftBarButtonItem = .close(self, action: #selector(closeWorkflow))
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
    navigationItem.backButtonDisplayMode = .minimal
  }

  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.refreshControl = UIRefreshControl(self, action: #selector(refreshTransactions))
  }
}

// MARK: - Actions

extension AddCategoryTransactionSelectionVC {
  @objc
  private func appMovedToForeground() {
    ASPerformBlockOnMainThread {
      self.fetchTransactions()
    }
  }

  @objc
  private func refreshTransactions() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.fetchTransactions()
    }
  }

  @objc
  private func closeWorkflow() {
    navigationController?.dismiss(animated: true)
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

  private func fetchTransactions() {
    Up.listTransactions { (result) in
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
    if navigationItem.title != "Select Transaction" {
      navigationItem.title = "Select Transaction"
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

extension AddCategoryTransactionSelectionVC: ASTableDataSource {
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

extension AddCategoryTransactionSelectionVC: ASTableDelegate {
  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    let transaction = filteredTransactions[indexPath.row]
    tableNode.deselectRow(at: indexPath, animated: true)
    if let category = category {
      let hud = MBProgressHUD(view: view, animationType: .zoomIn)
      hud.label.attributedText = "Processing".styled(with: .provenance)
      view.addSubview(hud)
      hud.show(animated: true)
      Up.categorise(transaction: transaction, category: category) { (error) in
        if let error = error {
          GrowingNotificationBanner(title: "Failed",
                                    subtitle: error.underlyingError?.localizedDescription ?? error.localizedDescription,
                                    style: .danger,
                                    duration: 2.0).show()
        } else {
          GrowingNotificationBanner(title: "Success",
                                    subtitle: "The category for \(transaction.attributes.description) was set to \(category.attributes.name).",
                                    style: .success,
                                    duration: 2.0).show()
        }
        hud.hide(animated: true)
        self.closeWorkflow()
      }
    } else {
      let viewController = AddCategoryCategorySelectionVC(transaction: transaction)
      navigationController?.pushViewController(viewController, animated: true)
    }
  }
}

// MARK: - UISearchBarDelegate

extension AddCategoryTransactionSelectionVC: UISearchBarDelegate {
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
