import UIKit
import Alamofire
import Rswift

class AccountsCVC: CollectionViewController {
    let searchController = UISearchController(searchResultsController: nil)
    let refreshControl = RefreshControl(frame: .zero)
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, AccountResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, AccountResource>
    
    private var accountsStatusCode: Int = 0
    private var accounts: [AccountResource] = []
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
            cellProvider: {  collectionView, indexPath, account in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AccountCollectionViewCell.reuseIdentifier, for: indexPath) as! AccountCollectionViewCell
                
                cell.account = account
                
                return cell
            }
        )
    }
    
    private func applySnapshot(animate: Bool = true) {
        var snapshot = Snapshot()
        
        snapshot.appendSections(Section.allCases)
        
        snapshot.appendItems(filteredAccountsList.data, toSection: .main)
        
        if snapshot.itemIdentifiers.isEmpty && accountsError.isEmpty && accountsErrorResponse.isEmpty  {
            if accounts.isEmpty && accountsStatusCode == 0 {
                collectionView.backgroundView = {
                    let view = UIView()
                    
                    let loadingIndicator = ActivityIndicator(style: .medium)
                    view.addSubview(loadingIndicator)
                    
                    loadingIndicator.center(in: view)
                    
                    loadingIndicator.startAnimating()
                    
                    return view
                }()
            } else {
                collectionView.backgroundView = {
                    let view = UIView()
                    
                    let label = UILabel()
                    view.addSubview(label)
                    
                    label.center(in: view)
                    
                    label.textAlignment = .center
                    label.textColor = .label
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = "No Accounts"
                    
                    return view
                }()
            }
        } else {
            if !accountsError.isEmpty {
                collectionView.backgroundView = {
                    let view = UIView()
                    
                    let label = UILabel()
                    view.addSubview(label)
                    
                    label.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    label.center(in: view)
                    
                    label.textAlignment = .center
                    label.textColor = .label
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = accountsError
                    
                    return view
                }()
            } else if !accountsErrorResponse.isEmpty {
                collectionView.backgroundView = {
                    let view = UIView()
                    
                    let titleLabel = UILabel()
                    let detailLabel = UILabel()
                    let verticalStack = UIStackView()
                    
                    view.addSubview(verticalStack)
                    
                    titleLabel.translatesAutoresizingMaskIntoConstraints = false
                    titleLabel.textAlignment = .center
                    titleLabel.textColor = .systemRed
                    titleLabel.font = R.font.circularStdBold(size: UIFont.labelFontSize)
                    titleLabel.numberOfLines = 0
                    titleLabel.text = accountsErrorResponse.first?.title
                    
                    detailLabel.translatesAutoresizingMaskIntoConstraints = false
                    detailLabel.textAlignment = .center
                    detailLabel.textColor = .label
                    detailLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    detailLabel.numberOfLines = 0
                    detailLabel.text = accountsErrorResponse.first?.detail
                    
                    verticalStack.addArrangedSubview(titleLabel)
                    verticalStack.addArrangedSubview(detailLabel)
                    
                    verticalStack.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    verticalStack.center(in: view)
                    
                    verticalStack.axis = .vertical
                    verticalStack.alignment = .center
                    verticalStack.distribution = .fill
                    
                    return view
                }()
            } else {
                collectionView.backgroundView = nil
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
        applySnapshot()
        
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
    }
    
    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.walletPass(), style: .plain, target: self, action: nil)
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func configureSearch() {
        searchController.delegate = self
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        
        searchController.searchBar.delegate = self
        
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
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
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        
        AF.request(UpApi.Accounts().listAccounts, method: .get, parameters: pageSize100Param, headers: headers).responseJSON { response in
            self.accountsStatusCode = response.response?.statusCode ?? 0
            
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Account.self, from: response.data!) {
                        print("Accounts JSON decoding succeeded")
                        
                        self.accounts = decodedResponse.data
                        self.accountsPagination = decodedResponse.links
                        self.accountsError = ""
                        self.accountsErrorResponse = []
                        
                        if !decodedResponse.data.isEmpty {
                            if self.navigationItem.searchController == nil {
                                self.navigationItem.searchController = self.searchController
                            }
                        } else {
                            if self.navigationItem.searchController != nil {
                                self.navigationItem.searchController = nil
                            }
                        }
                        
                        if self.navigationItem.title != "Accounts" {
                            self.navigationItem.title = "Accounts"
                        }
                        
                        self.applySnapshot()
                        self.collectionView.refreshControl?.endRefreshing()
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        print("Accounts Error JSON decoding succeeded")
                        
                        self.accountsErrorResponse = decodedResponse.errors
                        self.accountsError = ""
                        self.accounts = []
                        self.accountsPagination = Pagination(prev: nil, next: nil)
                        
                        if self.navigationItem.searchController != nil {
                            self.navigationItem.searchController = nil
                        }
                        
                        if self.navigationItem.title != "Errors" {
                            self.navigationItem.title = "Errors"
                        }
                        
                        self.applySnapshot()
                        self.collectionView.refreshControl?.endRefreshing()
                    } else {
                        print("Accounts JSON decoding failed")
                        
                        self.accountsError = "JSON Decoding Failed!"
                        self.accountsErrorResponse = []
                        self.accounts = []
                        self.accountsPagination = Pagination(prev: nil, next: nil)
                        
                        if self.navigationItem.searchController != nil {
                            self.navigationItem.searchController = nil
                        }
                        
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        
                        self.applySnapshot()
                        self.collectionView.refreshControl?.endRefreshing()
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
                    
                    self.accountsError = response.error?.localizedDescription ?? "Unknown Error!"
                    self.accountsErrorResponse = []
                    self.accounts = []
                    self.accountsPagination = Pagination(prev: nil, next: nil)
                    
                    if self.navigationItem.searchController != nil {
                        self.navigationItem.searchController = nil
                    }
                    
                    if self.navigationItem.title != "Error" {
                        self.navigationItem.title = "Error"
                    }
                    
                    self.applySnapshot()
                    self.collectionView.refreshControl?.endRefreshing()
            }
            self.searchController.searchBar.placeholder = "Search \(self.accounts.count.description) \(self.accounts.count == 1 ? "Account" : "Accounts")"
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let transaction = dataSource.itemIdentifier(for: indexPath)!
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy Balance", image: R.image.dollarsignCircle()) { _ in
                    UIPasteboard.general.string = transaction.attributes.balance.valueShort
                },
                UIAction(title: "Copy Display Name", image: R.image.textAlignright()) { _ in
                    UIPasteboard.general.string = transaction.attributes.displayName
                }
            ])
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigationController?.pushViewController({let vc = R.storyboard.transactionsByAccount.transactionsByAccountController()!;vc.account = dataSource.itemIdentifier(for: indexPath);return vc}(), animated: true)
    }
}

extension AccountsCVC: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySnapshot()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searchBar.text = ""
            applySnapshot()
        }
    }
}
