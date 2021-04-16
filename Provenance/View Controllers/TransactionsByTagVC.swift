import UIKit
import Alamofire
import TinyConstraints
import Rswift

class TransactionsByTagVC: TableViewController {
    var tag: TagResource!
    
    let tableRefreshControl = RefreshControl(frame: .zero)
    let searchController = UISearchController(searchResultsController: nil)
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, TransactionResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, TransactionResource>
    
    private var categories: [CategoryResource] = []
    private var accounts: [AccountResource] = []
    
    private var transactionsStatusCode: Int = 0
    private var transactions: [TransactionResource] = []
    private var transactionsPagination: Pagination = Pagination(prev: nil, next: nil)
    private var transactionsErrorResponse: [ErrorObject] = []
    private var transactionsError: String = ""
    
    private var filteredTransactionList: Transaction {
        return Transaction(data: filteredTransactions, links: transactionsPagination)
    }
    
    private lazy var dataSource = makeDataSource()
    
    private enum Section: CaseIterable {
        case main
    }
    
    private func makeDataSource() -> DataSource {
        return DataSource(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, transaction in
                let cell = tableView.dequeueReusableCell(withIdentifier: TransactionTableViewCell.reuseIdentifier, for: indexPath) as! TransactionTableViewCell
                
                cell.transaction = transaction
                
                return cell
            }
        )
    }
    
    private func applySnapshot(animate: Bool = false) {
        var snapshot = Snapshot()
        
        snapshot.appendSections(Section.allCases)
        
        snapshot.appendItems(filteredTransactionList.data, toSection: .main)
        
        if snapshot.itemIdentifiers.isEmpty && transactionsError.isEmpty && transactionsErrorResponse.isEmpty  {
            if transactions.isEmpty && transactionsStatusCode == 0 {
                tableView.backgroundView = {
                    let view = UIView()
                    
                    let loadingIndicator = ActivityIndicator(style: .medium)
                    view.addSubview(loadingIndicator)
                    
                    loadingIndicator.center(in: view)
                    
                    loadingIndicator.startAnimating()
                    
                    return view
                }()
            } else {
                tableView.backgroundView = {
                    let view = UIView()
                    
                    let label = UILabel()
                    view.addSubview(label)
                    
                    label.center(in: view)
                    
                    label.textAlignment = .center
                    label.textColor = .label
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = "No Transactions"
                    
                    return view
                }()
            }
        } else {
            if !transactionsError.isEmpty {
                tableView.backgroundView = {
                    let view = UIView()
                    
                    let label = UILabel()
                    view.addSubview(label)
                    
                    label.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    label.center(in: view)
                    
                    label.textAlignment = .center
                    label.textColor = .label
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = transactionsError
                    
                    return view
                }()
            } else if !transactionsErrorResponse.isEmpty {
                tableView.backgroundView = {
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
                    titleLabel.text = transactionsErrorResponse.first?.title
                    
                    detailLabel.translatesAutoresizingMaskIntoConstraints = false
                    detailLabel.textAlignment = .center
                    detailLabel.textColor = .label
                    detailLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    detailLabel.numberOfLines = 0
                    detailLabel.text = transactionsErrorResponse.first?.detail
                    
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
                tableView.backgroundView = nil
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: animate)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigation()
        setupSearch()
        setupRefreshControl()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        applySnapshot()
        
        fetchTransactions()
        fetchCategories()
        fetchAccounts()
    }
}

extension TransactionsByTagVC {
    private var filteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
            searchController.searchBar.text!.isEmpty || transaction.attributes.description.localizedStandardContains(searchController.searchBar.text!)
        }
    }

    @objc private func appMovedToForeground() {
        applySnapshot()
    }
    
    @objc private func refreshTransactions() {
        #if targetEnvironment(macCatalyst)
        let loadingView = ActivityIndicator(style: .medium)
        
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loadingView), animated: true)
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchTransactions()
            self.fetchCategories()
            self.fetchAccounts()
        }
    }
    
    private func setProperties() {
        title = "Transactions by Tag"
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func setupNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle(), style: .plain, target: self, action: nil)
        
        #if targetEnvironment(macCatalyst)
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTransactions)), animated: true)
        #endif
        
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupSearch() {
        searchController.delegate = self
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        
        searchController.searchBar.delegate = self
        
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
    }
    
    private func setupRefreshControl() {
        tableRefreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
    }
    
    private func setupTableView() {
        tableView.refreshControl = tableRefreshControl
        tableView.dataSource = dataSource
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: TransactionTableViewCell.reuseIdentifier)
    }
    
    private func fetchTransactions() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        
        AF.request(UpApi.Transactions().listTransactions, method: .get, parameters: filterTagAndPageSize100Params(tagId: tag.id), headers: headers).responseJSON { response in
            self.transactionsStatusCode = response.response?.statusCode ?? 0
            
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: response.data!) {
                        self.transactions = decodedResponse.data
                        self.transactionsPagination = decodedResponse.links
                        self.transactionsError = ""
                        self.transactionsErrorResponse = []
                        
                        if !decodedResponse.data.isEmpty {
                            if self.navigationItem.searchController == nil {
                                self.navigationItem.searchController = self.searchController
                            }
                        } else {
                            if self.navigationItem.searchController != nil {
                                self.navigationItem.searchController = nil
                            }
                        }
                        
                        self.navigationItem.title = self.tag.id
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        
                        self.applySnapshot()
                        self.refreshControl?.endRefreshing()
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        self.transactionsErrorResponse = decodedResponse.errors
                        self.transactionsError = ""
                        self.transactions = []
                        self.transactionsPagination = Pagination(prev: nil, next: nil)
                        
                        if self.navigationItem.searchController != nil {
                            self.navigationItem.searchController = nil
                        }
                        
                        if self.navigationItem.title != "Errors" {
                            self.navigationItem.title = "Errors"
                        }
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        
                        self.applySnapshot()
                        self.refreshControl?.endRefreshing()
                    } else {
                        self.transactionsError = "JSON Decoding Failed!"
                        self.transactionsErrorResponse = []
                        self.transactions = []
                        self.transactionsPagination = Pagination(prev: nil, next: nil)
                        
                        if self.navigationItem.searchController != nil {
                            self.navigationItem.searchController = nil
                        }
                        
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        
                        self.applySnapshot()
                        self.refreshControl?.endRefreshing()
                    }
                case .failure:
                    self.transactionsError = response.error?.localizedDescription ?? "Unknown Error!"
                    self.transactionsErrorResponse = []
                    self.transactions = []
                    self.transactionsPagination = Pagination(prev: nil, next: nil)
                    
                    if self.navigationItem.searchController != nil {
                        self.navigationItem.searchController = nil
                    }
                    
                    if self.navigationItem.title != "Error" {
                        self.navigationItem.title = "Error"
                    }
                    
                    #if targetEnvironment(macCatalyst)
                    self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                    #endif
                    
                    self.applySnapshot()
                    self.refreshControl?.endRefreshing()
            }
            self.searchController.searchBar.placeholder = "Search \(self.transactions.count.description) \(self.transactions.count == 1 ? "Transaction" : "Transactions")"
        }
    }
    
    private func fetchCategories() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        
        AF.request(UpApi.Categories().listCategories, method: .get, headers: headers).responseJSON { response in
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Category.self, from: response.data!) {
                        self.categories = decodedResponse.data
                    } else {
                        print("Categories JSON decoding failed")
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
            }
        }
    }
    
    private func fetchAccounts() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        
        AF.request(UpApi.Accounts().listAccounts, method: .get, parameters: pageSize100Param, headers: headers).responseJSON { response in
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Account.self, from: response.data!) {
                        self.accounts = decodedResponse.data
                    } else {
                        print("Accounts JSON decoding failed")
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
            }
        }
    }
}

extension TransactionsByTagVC {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        navigationController?.pushViewController({let vc = TransactionDetailVC(style: .grouped);vc.transaction = dataSource.itemIdentifier(for: indexPath);vc.categories = self.categories;vc.accounts = self.accounts;return vc}(), animated: true)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let transaction = dataSource.itemIdentifier(for: indexPath)!
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy Description", image: R.image.textAlignright()) { _ in
                    UIPasteboard.general.string = transaction.attributes.description
                },
                UIAction(title: "Copy Creation Date", image: R.image.calendarCircle()) { _ in
                    UIPasteboard.general.string = transaction.attributes.creationDate
                },
                UIAction(title: "Copy Amount", image: R.image.dollarsignCircle()) { _ in
                    UIPasteboard.general.string = transaction.attributes.amount.valueShort
                },
                UIAction(title: "Remove", image: R.image.trash(), attributes: .destructive) { _ in
                    let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

                    let confirmAction = UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
                        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!

                        var request = URLRequest(url: url)

                        request.httpMethod = "DELETE"
                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.addValue("Bearer \(appDefaults.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")

                        let bodyObject: [String : Any] = [
                            "data": [
                                [
                                    "type": "tags",
                                    "id": self.tag.id
                                ]
                            ]
                        ]

                        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])

                        URLSession.shared.dataTask(with: request) { data, response, error in
                            if error == nil {
                                let statusCode = (response as! HTTPURLResponse).statusCode

                                if statusCode != 204 {
                                    DispatchQueue.main.async {
                                        let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)

                                        let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                                        let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]

                                        let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                                        let messageAttrString = NSMutableAttributedString(string: "\(self.tag.id) was not removed from \(transaction.attributes.description).", attributes: messageFont)

                                        ac.setValue(titleAttrString, forKey: "attributedTitle")
                                        ac.setValue(messageAttrString, forKey: "attributedMessage")

                                        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)

                                        dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

                                        ac.addAction(dismissAction)

                                        self.present(ac, animated: true)

                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.fetchTransactions()
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)

                                    let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                                    let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]

                                    let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                                    let messageAttrString = NSMutableAttributedString(string: error?.localizedDescription ?? "\(self.tag.id) was not removed from \(transaction.attributes.description).", attributes: messageFont)

                                    ac.setValue(titleAttrString, forKey: "attributedTitle")
                                    ac.setValue(messageAttrString, forKey: "attributedMessage")

                                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)

                                    dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

                                    ac.addAction(dismissAction)

                                    self.present(ac, animated: true)
                                }
                            }
                        }
                        .resume()
                    })
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

                    cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

                    ac.addAction(confirmAction)
                    ac.addAction(cancelAction)

                    self.present(ac, animated: true)
                }
            ])
        }
    }
}

extension TransactionsByTagVC: UISearchControllerDelegate, UISearchBarDelegate {
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
