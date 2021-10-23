import IGListDiffKit
import AsyncDisplayKit
import Alamofire

final class AccountsVC: ASViewController {
  // MARK: - Properties

  private lazy var searchController = UISearchController.accounts(self)

  private let collectionNode = ASCollectionNode(collectionViewLayout: .twoColumnGridLayout)

  private lazy var accountFilter: AccountTypeOptionEnum = UserDefaults.provenance.appAccountFilter {
    didSet {
      if UserDefaults.provenance.accountFilter != accountFilter.rawValue {
        UserDefaults.provenance.accountFilter = accountFilter.rawValue
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

  private var oldAccountCellModels = [AccountCellModel]()

  private var filteredAccounts: [AccountResource] {
    return accounts.filtered(filter: accountFilter, searchBar: searchController.searchBar)
  }

  // MARK: - Life Cycle

  override init() {
    super.init(node: collectionNode)
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
    configureCollectionNode()
    applySnapshot(override: true)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchAccounts()
  }
}

// MARK: - Configuration

private extension AccountsVC {
  private func configureSelf() {
    title = "Accounts"
    definesPresentationContext = true
  }

  private func configureObservers() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(appMovedToForeground),
                                           name: .willEnterForegroundNotification,
                                           object: nil)
    apiKeyObserver = UserDefaults.provenance.observe(\.apiKey, options: .new) { [weak self] (_, _) in
      self?.fetchAccounts()
    }
    accountFilterObserver = UserDefaults.provenance.observe(\.accountFilter, options: .new) { [weak self] (_, change) in
      guard let value = change.newValue, let accountFilter = AccountTypeOptionEnum(rawValue: value) else { return }
      self?.accountFilter = accountFilter
    }
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForegroundNotification, object: nil)
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

private extension AccountsVC {
  @objc
  private func appMovedToForeground() {
    fetchAccounts()
  }

  @objc
  private func refreshAccounts() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.fetchAccounts()
    }
  }

  private func applySnapshot(override: Bool = false) {
    let result = ListDiffPaths(
      fromSection: 0,
      toSection: 0,
      oldArray: oldAccountCellModels,
      newArray: filteredAccounts.accountCellModels,
      option: .equality
    ).forBatchUpdates()

    if result.hasChanges || override || !accountsError.isEmpty || noAccounts {
      if filteredAccounts.isEmpty && accountsError.isEmpty {
        if accounts.isEmpty && !noAccounts {
          collectionNode.view.backgroundView = .loadingView(frame: collectionNode.bounds, contentType: .accounts)
        } else {
          collectionNode.view.backgroundView = .noContentView(frame: collectionNode.bounds, type: .accounts)
        }
      } else {
        if !accountsError.isEmpty {
          collectionNode.view.backgroundView = .errorView(frame: collectionNode.bounds, text: accountsError)
        } else {
          if collectionNode.view.backgroundView != nil {
            collectionNode.view.backgroundView = nil
          }
        }
      }

      let batchUpdates = { [self] in
        collectionNode.deleteItems(at: result.deletes)
        collectionNode.insertItems(at: result.inserts)
        result.moves.forEach { collectionNode.moveItem(at: $0.from, to: $0.to) }
        collectionNode.reloadItems(at: result.updates)
        oldAccountCellModels = filteredAccounts.accountCellModels
      }

      collectionNode.performBatchUpdates(batchUpdates)
    }
  }

  private func fetchAccounts() {
    Up.listAccounts { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(accounts):
          self.display(accounts)
        case let .failure(error):
          self.display(error)
        }
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
    accountsError = error.errorDescription ?? error.localizedDescription
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
    let node = AccountCellNode(account: account)
    return {
      node
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
        return TransactionsByAccountVC(account: account)
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
