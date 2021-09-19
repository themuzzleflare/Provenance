import UIKit
import IGListKit
import AsyncDisplayKit

final class AccountsVC: ASViewController {
  // MARK: - Properties
  
  private lazy var searchController = UISearchController.accounts(self)
  
  private let collectionNode = ASCollectionNode(collectionViewLayout: .twoColumnGridLayout)
  
  private lazy var collectionRefreshControl = UIRefreshControl(self, selector: #selector(refreshAccounts))
  
  private var apiKeyObserver: NSKeyValueObservation?
  
  private var noAccounts: Bool = false
  
  private var accounts = [AccountResource]() {
    didSet {
      noAccounts = accounts.isEmpty
      applySnapshot()
      collectionNode.view.refreshControl?.endRefreshing()
      searchController.searchBar.placeholder = "Search \(accounts.count.description) \(accounts.count == 1 ? "Account" : "Accounts")"
    }
  }
  
  private var accountsError = String()
  
  private var oldFilteredAccounts = [AccountResource]()
  
  private var filteredAccounts: [AccountResource] {
    return accounts.filtered(searchBar: searchController.searchBar)
  }
  
  // MARK: - Life Cycle

  override init() {
    super.init(node: collectionNode)
  }

  deinit {
    removeObservers()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureObservers()
    configureProperties()
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
  private func configureProperties() {
    title = "Accounts"
    definesPresentationContext = true
  }

  private func configureObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appMovedToForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
    apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { [weak self] (_, change) in
      guard let weakSelf = self, let value = change.newValue else { return }
      DispatchQueue.main.async {
        weakSelf.fetchAccounts()
      }
    }
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self)
    apiKeyObserver?.invalidate()
    apiKeyObserver = nil
  }
  
  private func configureNavigation() {
    navigationItem.title = "Loading"
    navigationItem.largeTitleDisplayMode = .always
    navigationItem.backBarButtonItem = UIBarButtonItem(image: .walletPass)
    navigationItem.searchController = searchController
  }
  
  private func configureCollectionNode() {
    collectionNode.dataSource = self
    collectionNode.delegate = self
    collectionNode.view.refreshControl = collectionRefreshControl
    collectionNode.backgroundColor = .systemGroupedBackground
  }
}

// MARK: - Actions

private extension AccountsVC {
  @objc private func appMovedToForeground() {
    fetchAccounts()
  }
  
  @objc private func refreshAccounts() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
      fetchAccounts()
    }
  }
  
  private func applySnapshot(override: Bool = false) {
    let result = ListDiffPaths(
      fromSection: 0,
      toSection: 0,
      oldArray: oldFilteredAccounts,
      newArray: filteredAccounts,
      option: .equality
    ).forBatchUpdates()
    if result.hasChanges || override || !accountsError.isEmpty || noAccounts {
      if filteredAccounts.isEmpty && accountsError.isEmpty {
        if accounts.isEmpty && !noAccounts {
          collectionNode.view.backgroundView = .loadingView(frame: collectionNode.bounds)
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
        oldFilteredAccounts = filteredAccounts
      }
      collectionNode.performBatchUpdates(batchUpdates)
    }
  }
  
  private func fetchAccounts() {
    UpFacade.listAccounts { [self] (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(accounts):
          display(accounts)
        case let .failure(error):
          display(error)
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
  
  private func display(_ error: NetworkError) {
    accountsError = error.description
    accounts = []
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
    let node = AccountCellNode(account: filteredAccounts[indexPath.item])
    return {
      node
    }
  }
}

// MARK: - ASCollectionDelegate

extension AccountsVC: ASCollectionDelegate {
  func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
    collectionNode.deselectItem(at: indexPath, animated: true)
    let account = filteredAccounts[indexPath.item]
    navigationController?.pushViewController(TransactionsByAccountVC(account: account), animated: true)
  }

  func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let account = filteredAccounts[indexPath.item]
    return UIContextMenuConfiguration(elements: [
      .copyAccountBalance(account: account),
      .copyAccountDisplayName(account: account)
    ])
  }
}

// MARK: - UISearchBarDelegate

extension AccountsVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    applySnapshot()
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if !searchBar.text!.isEmpty {
      searchBar.clear()
      applySnapshot()
    }
  }

  func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    if !searchBar.text!.isEmpty {
      applySnapshot()
    }
  }
}
