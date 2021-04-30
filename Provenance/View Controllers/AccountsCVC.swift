import UIKit
import Alamofire
import TinyConstraints
import Rswift

class AccountsCVC: CollectionViewController {
    let searchController = SearchController(searchResultsController: nil)
    let refreshControl = RefreshControl(frame: .zero)
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, AccountResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, AccountResource>
    
    private var accountsStatusCode: Int = 0
    private var accounts: [AccountResource] = [] {
        didSet {
            applySnapshot()
            collectionView.reloadData()
            collectionView.refreshControl?.endRefreshing()
            searchController.searchBar.placeholder = "Search \(accounts.count.description) \(accounts.count == 1 ? "Account" : "Accounts")"
        }
    }
    private var accountsPagination: Pagination = Pagination(prev: nil, next: nil)
    private var accountsErrorResponse: [ErrorObject] = []
    private var accountsError: String = ""
    private var filteredAccounts: [AccountResource] {
        accounts.filter { account in
            searchController.searchBar.text!.isEmpty || account.attributes.displayName.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    private var filteredAccountsList: Account {
        return Account(data: filteredAccounts, links: accountsPagination)
    }
    
    private enum Section: CaseIterable {
        case main
    }
    
    private lazy var dataSource = makeDataSource()
    
    private func makeDataSource() -> DataSource {
        return DataSource(
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath, account in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AccountCollectionViewCell.reuseIdentifier, for: indexPath) as! AccountCollectionViewCell
                cell.account = account
                return cell
            }
        )
    }
    
    private func applySnapshot(animate: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(filteredAccountsList.data, toSection: .main)
        if snapshot.itemIdentifiers.isEmpty && accountsError.isEmpty && accountsErrorResponse.isEmpty  {
            if accounts.isEmpty && accountsStatusCode == 0 {
                collectionView.backgroundView = {
                    let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))
                    let loadingIndicator = ActivityIndicator(style: .medium)
                    view.addSubview(loadingIndicator)
                    loadingIndicator.center(in: view)
                    loadingIndicator.startAnimating()
                    return view
                }()
            } else {
                collectionView.backgroundView = {
                    let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))
                    let label = UILabel()
                    view.addSubview(label)
                    label.center(in: view)
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.adobeCleanRegular(size: UIFont.labelFontSize)
                    label.numberOfLines = 1
                    label.text = "No Accounts"
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
                    label.font = R.font.adobeCleanRegular(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = accountsError
                    return view
                }()
            } else if !accountsErrorResponse.isEmpty {
                collectionView.backgroundView = {
                    let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))
                    let titleLabel = UILabel()
                    let detailLabel = UILabel()
                    let verticalStack = UIStackView()
                    view.addSubview(verticalStack)
                    titleLabel.translatesAutoresizingMaskIntoConstraints = false
                    titleLabel.textAlignment = .center
                    titleLabel.textColor = .systemRed
                    titleLabel.font = R.font.adobeCleanBold(size: UIFont.labelFontSize)
                    titleLabel.numberOfLines = 0
                    titleLabel.text = accountsErrorResponse.first?.title
                    detailLabel.translatesAutoresizingMaskIntoConstraints = false
                    detailLabel.textAlignment = .center
                    detailLabel.textColor = .secondaryLabel
                    detailLabel.font = R.font.adobeCleanRegular(size: UIFont.labelFontSize)
                    detailLabel.numberOfLines = 0
                    detailLabel.text = accountsErrorResponse.first?.detail
                    verticalStack.addArrangedSubview(titleLabel)
                    verticalStack.addArrangedSubview(detailLabel)
                    verticalStack.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    verticalStack.center(in: view)
                    verticalStack.axis = .vertical
                    verticalStack.alignment = .center
                    verticalStack.distribution = .fill
                    verticalStack.spacing = 0
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureProperties()
        configureNavigation()
        configureSearch()
        configureRefreshControl()
        configureCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        applySnapshot(animate: false)
        fetchCategories()
    }
}

private extension AccountsCVC {
    @objc private func appMovedToForeground() {
        fetchCategories()
    }
    
    @objc private func refreshCategories() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchCategories()
        }
    }
    
    private func configureProperties() {
        title = "Accounts"
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.walletPass(), style: .plain, target: self, action: nil)
        navigationItem.searchController = searchController
    }
    
    private func configureSearch() {
        searchController.searchBar.delegate = self
    }
    
    private func configureRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshCategories), for: .valueChanged)
    }
    
    private func configureCollectionView() {
        collectionView.refreshControl = refreshControl
        collectionView.dataSource = dataSource
        collectionView.register(AccountCollectionViewCell.self, forCellWithReuseIdentifier: AccountCollectionViewCell.reuseIdentifier)
    }
    
    private func fetchCategories() {
        AF.request(UpAPI.Accounts().listAccounts, method: .get, parameters: pageSize100Param, headers: [acceptJsonHeader, authorisationHeader]).responseJSON { response in
            self.accountsStatusCode = response.response?.statusCode ?? 0
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Account.self, from: response.data!) {
                        self.accountsError = ""
                        self.accountsErrorResponse = []
                        self.accountsPagination = decodedResponse.links
                        self.accounts = decodedResponse.data
                        if self.navigationItem.title != "Accounts" {
                            self.navigationItem.title = "Accounts"
                        }
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        self.accountsErrorResponse = decodedResponse.errors
                        self.accountsError = ""
                        self.accountsPagination = Pagination(prev: nil, next: nil)
                        self.accounts = []
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                    } else {
                        self.accountsError = "JSON Decoding Failed!"
                        self.accountsErrorResponse = []
                        self.accountsPagination = Pagination(prev: nil, next: nil)
                        self.accounts = []
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                    }
                case .failure:
                    self.accountsError = response.error?.localizedDescription ?? "Unknown Error!"
                    self.accountsErrorResponse = []
                    self.accountsPagination = Pagination(prev: nil, next: nil)
                    self.accounts = []
                    if self.navigationItem.title != "Error" {
                        self.navigationItem.title = "Error"
                    }
            }
        }
    }
}

extension AccountsCVC {
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let account = dataSource.itemIdentifier(for: indexPath)!
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
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigationController?.pushViewController({let vc = TransactionsByAccountVC(style: .grouped);vc.account = dataSource.itemIdentifier(for: indexPath);return vc}(), animated: true)
    }
}

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
