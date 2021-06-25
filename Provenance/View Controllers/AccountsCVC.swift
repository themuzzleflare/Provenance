import UIKit
import FLAnimatedImage
import TinyConstraints
import Rswift

final class AccountsCVC: CollectionViewController {
    // MARK: - Properties

    private enum Section {
        case main
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, AccountResource>
    private typealias AccountCell = UICollectionView.CellRegistration<AccountCollectionViewCell, AccountResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, AccountResource>

    private lazy var dataSource = makeDataSource()

    private let searchController = SearchController(searchResultsController: nil)
    private let collectionRefreshControl = RefreshControl(frame: .zero)
    private let cellRegistration = AccountCell { cell, indexPath, account in
        cell.account = account
    }

    private var apiKeyObserver: NSKeyValueObservation?
    private var noAccounts: Bool = false
    private var accounts: [AccountResource] = [] {
        didSet {
            noAccounts = accounts.isEmpty
            applySnapshot()
            collectionView.reloadData()
            collectionView.refreshControl?.endRefreshing()
            searchController.searchBar.placeholder = "Search \(accounts.count.description) \(accounts.count == 1 ? "Account" : "Accounts")"
        }
    }
    private var accountsPagination: Pagination = Pagination(prev: nil, next: nil)
    private var accountsError: String = ""
    private var filteredAccounts: [AccountResource] {
        accounts.filter { account in
            searchController.searchBar.text!.isEmpty || account.attributes.displayName.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    private var filteredAccountsList: Account {
        Account(data: filteredAccounts, links: accountsPagination)
    }
    
    // MARK: - View Life Cycle
    
    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
        configureProperties()
        configureNavigation()
        configureSearch()
        configureRefreshControl()
        configureCollectionView()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySnapshot(animate: false)
        fetchAccounts()
    }
}

// MARK: - Configuration

private extension AccountsCVC {
    private func configureProperties() {
        title = "Accounts"
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { object, change in
            self.fetchAccounts()
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.walletPass())
        navigationItem.searchController = searchController
    }
    
    private func configureSearch() {
        searchController.searchBar.delegate = self
    }
    
    private func configureRefreshControl() {
        collectionRefreshControl.addTarget(self, action: #selector(refreshCategories), for: .valueChanged)
    }
    
    private func configureCollectionView() {
        collectionView.refreshControl = collectionRefreshControl
    }
}

// MARK: - Actions

private extension AccountsCVC {
    @objc private func appMovedToForeground() {
        fetchAccounts()
    }

    @objc private func refreshCategories() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchAccounts()
        }
    }

    private func makeDataSource() -> DataSource {
        DataSource(collectionView: collectionView) { collectionView, indexPath, account in
            collectionView.dequeueConfiguredReusableCell(using: self.cellRegistration, for: indexPath, item: account)
        }
    }

    private func applySnapshot(animate: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(filteredAccountsList.data, toSection: .main)
        if snapshot.itemIdentifiers.isEmpty && accountsError.isEmpty {
            if accounts.isEmpty && !noAccounts {
                collectionView.backgroundView = {
                    let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))
                    let loadingIndicator = FLAnimatedImageView()
                    loadingIndicator.animatedImage = upZapSpinTransparentBackground
                    loadingIndicator.width(100)
                    loadingIndicator.height(100)
                    view.addSubview(loadingIndicator)
                    loadingIndicator.center(in: view)
                    return view
                }()
            } else {
                collectionView.backgroundView = {
                    let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))
                    let icon = UIImageView(image: R.image.xmarkDiamond())
                    icon.tintColor = .secondaryLabel
                    icon.width(70)
                    icon.height(64)
                    let label = UILabel()
                    label.translatesAutoresizingMaskIntoConstraints = false
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: 23)
                    label.text = "No Accounts"
                    let vstack = UIStackView(arrangedSubviews: [icon, label])
                    vstack.axis = .vertical
                    vstack.alignment = .center
                    vstack.spacing = 10
                    view.addSubview(vstack)
                    vstack.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    vstack.center(in: view)
                    return view
                }()
            }
        } else {
            if !accountsError.isEmpty {
                collectionView.backgroundView = {
                    let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))
                    let label = UILabel()
                    view.addSubview(label)
                    label.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    label.center(in: view)
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = accountsError
                    return view
                }()
            } else {
                if collectionView.backgroundView != nil {
                    collectionView.backgroundView = nil
                }
            }
        }
        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    private func fetchAccounts() {
        upApi.listAccounts { result in
            switch result {
                case .success(let accounts):
                    DispatchQueue.main.async {
                        self.accountsError = ""
                        self.accounts = accounts
                        if self.navigationItem.title != "Accounts" {
                            self.navigationItem.title = "Accounts"
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.accountsError = errorString(for: error)
                        self.accounts = []
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                    }
            }
        }
    }
}

// MARK: - UICollectionViewDelegate

extension AccountsCVC {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigationController?.pushViewController({let vc = TransactionsByAccountVC(style: .insetGrouped);vc.account = dataSource.itemIdentifier(for: indexPath);return vc}(), animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let account = dataSource.itemIdentifier(for: indexPath)!
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy Balance", image: R.image.dollarsignCircle()) { action in
                UIPasteboard.general.string = account.attributes.balance.valueShort
            },
                UIAction(title: "Copy Display Name", image: R.image.textAlignright()) { action in
                UIPasteboard.general.string = account.attributes.displayName
            }
            ])
        }
    }
}

// MARK: - UISearchBarDelegate

extension AccountsCVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySnapshot()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if !searchBar.text!.isEmpty {
            searchBar.text = ""
            applySnapshot()
        }
    }
}
