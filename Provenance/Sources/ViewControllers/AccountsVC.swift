import UIKit
import IGListKit
import AsyncDisplayKit
import Alamofire

final class AccountsVC: ASViewController, UIProtocol {
  // MARK: - Properties

  var state: UIState = .initialLoad {
    didSet {
      if oldValue != state {
        UIUpdates.updateUI(state: state, contentType: .accounts, collection: .collectionNode(collectionNode))
      }
    }
  }

  private lazy var searchController = UISearchController.accounts(self)

  private let collectionNode = ASCollectionNode(collectionViewLayout: .twoColumnGrid)

  private lazy var accountFilter: AccountTypeOptionEnum = Store.provenance.appAccountFilter {
    didSet {
      if Store.provenance.accountFilter != accountFilter.rawValue {
        Store.provenance.accountFilter = accountFilter.rawValue
      }
      if searchController.searchBar.selectedScopeButtonIndex != accountFilter.rawValue {
        searchController.searchBar.selectedScopeButtonIndex = accountFilter.rawValue
      }
    }
  }

  private var apiKeyObserver: NSKeyValueObservation?

  private var accountFilterObserver: NSKeyValueObservation?

  private var noAccounts: Bool = false

  private var accounts = [AccountResource]() {
    didSet {
      noAccounts = accounts.isEmpty
      applySnapshot()
      collectionNode.view.refreshControl?.endRefreshing()
      searchController.searchBar.placeholder = accounts.searchBarPlaceholder
    }
  }

  private var accountsError = String()

  private var oldAccountCellModels = [ListDiffable]()

  private var filteredAccounts: [AccountResource] {
    return accounts.filtered(filter: accountFilter, searchBar: searchController.searchBar)
  }

  // MARK: - Life Cycle

  override init() {
    super.init(node: collectionNode)
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
    configureCollectionNode()
    applySnapshot(override: true)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchAccounts()
  }
}

// MARK: - Configuration

extension AccountsVC {
  private func configureSelf() {
    title = "Accounts"
    definesPresentationContext = true
  }

  private func configureObservers() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(appMovedToForeground),
                                           name: .willEnterForeground,
                                           object: nil)
    apiKeyObserver = Store.provenance.observe(\.apiKey, options: .new) { [weak self] (_, _) in
      ASPerformBlockOnMainThread {
        self?.fetchAccounts()
      }
    }
    accountFilterObserver = Store.provenance.observe(\.accountFilter, options: .new) { [weak self] (_, change) in
      ASPerformBlockOnMainThread {
        guard let value = change.newValue, let accountFilter = AccountTypeOptionEnum(rawValue: value) else { return }
        self?.accountFilter = accountFilter
      }
    }
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForeground, object: nil)
    apiKeyObserver?.invalidate()
    apiKeyObserver = nil
    accountFilterObserver?.invalidate()
    accountFilterObserver = nil
  }

  private func configureNavigation() {
    navigationItem.title = "Loading"
    navigationItem.largeTitleDisplayMode = .always
    navigationItem.backBarButtonItem = .walletPass
    navigationItem.searchController = searchController
  }

  private func configureCollectionNode() {
    collectionNode.dataSource = self
    collectionNode.delegate = self
    collectionNode.view.refreshControl = UIRefreshControl(self, action: #selector(refreshAccounts))
  }
}

// MARK: - Actions

extension AccountsVC {
  @objc
  private func appMovedToForeground() {
    ASPerformBlockOnMainThread {
      self.fetchAccounts()
    }
  }

  @objc
  private func refreshAccounts() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.fetchAccounts()
    }
  }

  private func applySnapshot(override: Bool = false) {
    UIUpdates.applySnapshot(oldArray: &oldAccountCellModels,
                            newArray: filteredAccounts.cellModels,
                            override: override,
                            state: &state,
                            contents: accounts,
                            filteredContents: filteredAccounts,
                            noContent: noAccounts,
                            error: accountsError,
                            contentType: .accounts,
                            collection: .collectionNode(collectionNode))
  }

  private func fetchAccounts() {
    Up.listAccounts { (result) in
      switch result {
      case let .success(accounts):
        self.display(accounts)
      case let .failure(error):
        self.display(error)
      }
    }
  }

  private func display(_ accounts: [AccountResource]) {
    accountsError = ""
    self.accounts = accounts
    if navigationItem.title != "Accounts" {
      navigationItem.title = "Accounts"
    }
  }

  private func display(_ error: AFError) {
    accountsError = error.underlyingError?.localizedDescription ?? error.localizedDescription
    accounts.removeAll()
    if navigationItem.title != "Error" {
      navigationItem.title = "Error"
    }
  }
}

// MARK: - ASCollectionDataSource

extension AccountsVC: ASCollectionDataSource {
  func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
    return filteredAccounts.count
  }

  func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
    let account = filteredAccounts[indexPath.item]
    return {
      AccountCellNode(model: account.cellModel)
    }
  }
}

// MARK: - ASCollectionDelegate

extension AccountsVC: ASCollectionDelegate {
  func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
    let account = filteredAccounts[indexPath.item]
    let viewController = TransactionsByAccountVC(account: account)
    collectionNode.deselectItem(at: indexPath, animated: true)
    navigationController?.pushViewController(viewController, animated: true)
  }

  func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let account = filteredAccounts[indexPath.item]
    return UIContextMenuConfiguration(
      previewProvider: {
        TransactionsByAccountVC(account: account)
      },
      elements: [
        .copyAccountBalance(account: account),
        .copyAccountDisplayName(account: account)
      ]
    )
  }
}

// MARK: - UISearchBarDelegate

extension AccountsVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    applySnapshot()
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if searchBar.searchTextField.hasText {
      searchBar.clear()
      applySnapshot()
    }
  }

  func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    if let value = AccountTypeOptionEnum(rawValue: selectedScope) {
      accountFilter = value
    }
    if searchBar.searchTextField.hasText {
      applySnapshot()
    }
  }
}
