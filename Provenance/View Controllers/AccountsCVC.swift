import UIKit
import FLAnimatedImage
import TinyConstraints
import Rswift

final class AccountsCVC: UIViewController {
    // MARK: - Properties

    private enum Section {
        case main
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, AccountResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, AccountResource>
    private typealias AccountCell = UICollectionView.CellRegistration<AccountCollectionViewCell, AccountResource>

    private lazy var dataSource = makeDataSource()

    private let accountsPagination = Pagination(prev: nil, next: nil)
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: twoColumnGridLayout())
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
    private var accountsError: String = ""
    private var filteredAccounts: [AccountResource] {
        accounts.filter { account in
            searchController.searchBar.text!.isEmpty || account.attributes.displayName.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    private var filteredAccountsList: Account {
        Account(data: filteredAccounts, links: accountsPagination)
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)

        configureProperties()
        configureNavigation()
        configureSearch()
        configureRefreshControl()
        configureCollectionView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.frame = view.bounds
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

        apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { [self] object, change in
            fetchAccounts()
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.walletPass())
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func configureSearch() {
        searchController.searchBar.delegate = self
    }
    
    private func configureRefreshControl() {
        collectionRefreshControl.addTarget(self, action: #selector(refreshCategories), for: .valueChanged)
    }
    
    private func configureCollectionView() {
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.refreshControl = collectionRefreshControl
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .systemGroupedBackground
    }
}

// MARK: - Actions

private extension AccountsCVC {
    @objc private func appMovedToForeground() {
        fetchAccounts()
    }

    @objc private func refreshCategories() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchAccounts()
        }
    }

    private func makeDataSource() -> DataSource {
        DataSource(collectionView: collectionView) { [self] collectionView, indexPath, account in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: account)
        }
    }

    private func applySnapshot(animate: Bool = true) {
        var snapshot = Snapshot()

        snapshot.appendSections([.main])
        snapshot.appendItems(filteredAccountsList.data, toSection: .main)

        if snapshot.itemIdentifiers.isEmpty && accountsError.isEmpty {
            if accounts.isEmpty && !noAccounts {
                collectionView.backgroundView = {
                    let view = UIView(frame: collectionView.bounds)

                    let loadingIndicator = FLAnimatedImageView()

                    view.addSubview(loadingIndicator)

                    loadingIndicator.centerInSuperview()
                    loadingIndicator.width(100)
                    loadingIndicator.height(100)
                    loadingIndicator.animatedImage = upZapSpinTransparentBackground

                    return view
                }()
            } else {
                collectionView.backgroundView = {
                    let view = UIView(frame: collectionView.bounds)

                    let icon = UIImageView(image: R.image.xmarkDiamond())

                    icon.width(70)
                    icon.height(64)
                    icon.tintColor = .secondaryLabel

                    let label = UILabel()

                    label.translatesAutoresizingMaskIntoConstraints = false
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: 23)
                    label.text = "No Accounts"

                    let vStack = UIStackView(arrangedSubviews: [icon, label])

                    view.addSubview(vStack)

                    vStack.horizontalToSuperview(insets: .horizontal(16))
                    vStack.centerInSuperview()
                    vStack.axis = .vertical
                    vStack.alignment = .center
                    vStack.spacing = 10

                    return view
                }()
            }
        } else {
            if !accountsError.isEmpty {
                collectionView.backgroundView = {
                    let view = UIView(frame: collectionView.bounds)

                    let label = UILabel()

                    view.addSubview(label)

                    label.horizontalToSuperview(insets: .horizontal(16))
                    label.centerInSuperview()
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
        if #available(iOS 15.0, *) {
            async {
                do {
                    let accounts = try await Up.listAccounts()
                    display(accounts)
                } catch {
                    display(error as! NetworkError)
                }
            }
        } else {
            Up.listAccounts { [self] result in
                DispatchQueue.main.async {
                    switch result {
                        case .success(let accounts):
                            display(accounts)
                        case .failure(let error):
                            display(error)
                    }
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
        accountsError = errorString(for: error)
        accounts = []

        if navigationItem.title != "Error" {
            navigationItem.title = "Error"
        }
    }
}

// MARK: - UICollectionViewDelegate

extension AccountsCVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = TransactionsByAccountVC()

        vc.account = dataSource.itemIdentifier(for: indexPath)

        navigationController?.pushViewController(vc, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let account = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy Balance", image: R.image.dollarsignCircle()) { _ in
                    UIPasteboard.general.string = account.attributes.balance.valueShort
                },
                UIAction(title: "Copy Display Name", image: R.image.textAlignright()) { _ in
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
