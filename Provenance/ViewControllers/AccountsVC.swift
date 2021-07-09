import UIKit
import FLAnimatedImage
import TinyConstraints
import Rswift

final class AccountsVC: UIViewController {
    // MARK: - Properties

    private enum Section {
        case main
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, AccountResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, AccountResource>
    private typealias AccountCell = UICollectionView.CellRegistration<AccountCollectionViewCell, AccountResource>

    private lazy var dataSource = makeDataSource()

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: twoColumnGridLayout())

    private let searchController = SearchController(searchResultsController: nil)

    private let collectionRefreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshAccounts), for: .valueChanged)
        return rc
    }()

    private let cellRegistration = AccountCell { cell, indexPath, account in
        cell.account = account
    }

    private var apiKeyObserver: NSKeyValueObservation?

    private var noAccounts: Bool = false

    private var accounts: [AccountResource] = [] {
        didSet {
            log.info("didSet accounts: \(accounts.count.description)")

            noAccounts = accounts.isEmpty
            applySnapshot()
            reloadSnapshot()
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
    
    // MARK: - Life Cycle

    deinit {
        log.debug("deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        log.debug("viewDidLoad")
        view.addSubview(collectionView)
        
        configureProperties()
        configureNavigation()
        configureSearch()
        configureCollectionView()
        applySnapshot()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        log.debug("viewDidLayoutSubviews")
        collectionView.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        log.debug("viewWillAppear(animated: \(animated.description))")
        fetchAccounts()
    }
}

// MARK: - Configuration

private extension AccountsVC {
    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Accounts"
        definesPresentationContext = true

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { [self] object, change in
            fetchAccounts()
        }
    }
    
    private func configureNavigation() {
        log.verbose("configureNavigation")

        navigationItem.title = "Loading"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.walletPass())
        navigationItem.searchController = searchController
    }
    
    private func configureSearch() {
        log.verbose("configureSearch")

        searchController.searchBar.delegate = self
    }
    
    private func configureCollectionView() {
        log.verbose("configureCollectionView")

        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.refreshControl = collectionRefreshControl
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .systemGroupedBackground
    }
}

// MARK: - Actions

private extension AccountsVC {
    @objc private func appMovedToForeground() {
        log.verbose("appMovedToForeground")

        fetchAccounts()
    }

    @objc private func refreshAccounts() {
        log.verbose("refreshAccounts")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchAccounts()
        }
    }

    private func makeDataSource() -> DataSource {
        log.verbose("makeDataSource")

        return DataSource(collectionView: collectionView) { [self] collectionView, indexPath, account in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: account)
        }
    }

    private func applySnapshot(animate: Bool = true) {
        log.verbose("applySnapshot(animate: \(animate.description))")

        var snapshot = Snapshot()

        snapshot.appendSections([.main])
        snapshot.appendItems(filteredAccounts, toSection: .main)

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

    private func reloadSnapshot() {
        var snap = dataSource.snapshot()

        if #available(iOS 15.0, *) {
            snap.reconfigureItems(snap.itemIdentifiers)
        } else {
            snap.reloadItems(snap.itemIdentifiers)
        }

        dataSource.apply(snap, animatingDifferences: false)
    }

    private func fetchAccounts() {
        log.verbose("fetchAccounts")

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
        log.verbose("display(accounts: \(accounts.count.description))")
        accountsError = ""
        self.accounts = accounts

        if navigationItem.title != "Accounts" {
            navigationItem.title = "Accounts"
        }
    }

    private func display(_ error: NetworkError) {
        log.verbose("display(error: \(errorString(for: error)))")

        accountsError = errorString(for: error)
        accounts = []

        if navigationItem.title != "Error" {
            navigationItem.title = "Error"
        }
    }
}

// MARK: - UICollectionViewDelegate

extension AccountsVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        log.debug("collectionView(didSelectItemAt indexPath: \(indexPath))")

        collectionView.deselectItem(at: indexPath, animated: true)

        if let account = dataSource.itemIdentifier(for: indexPath) {
            navigationController?.pushViewController(TransactionsByAccountVC(account: account), animated: true)
        }
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

extension AccountsVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        log.debug("searchBar(textDidChange searchText: \(searchText))")

        applySnapshot()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        log.debug("searchBarCancelButtonClicked")

        if !searchBar.text!.isEmpty {
            searchBar.text = ""
            applySnapshot()
        }
    }
}
