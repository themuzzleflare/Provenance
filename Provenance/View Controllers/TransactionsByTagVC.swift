import UIKit
import Alamofire
import NotificationBannerSwift
import TinyConstraints
import Rswift

class TransactionsByTagVC: TableViewController {
    // MARK: - Properties

    var tag: TagResource!

    private enum Section {
        case main
    }

    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, TransactionResource>

    private lazy var dataSource = makeDataSource()

    // UITableViewDiffableDataSource
    private class DataSource: UITableViewDiffableDataSource<Section, TransactionResource> {
        weak var parent: TransactionsByTagVC! = nil

        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }

        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            let transaction = itemIdentifier(for: indexPath)!
            if editingStyle == .delete {
                let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(self.parent.tag.id)\" from \"\(transaction.attributes.description)\"?", preferredStyle: .actionSheet)
                let confirmAction = UIAlertAction(title: "Remove", style: .destructive, handler: { [unowned self] _ in
                    let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!
                    var request = URLRequest(url: url)
                    let bodyObject: [String : Any] = [
                        "data": [
                            [
                                "type": "tags",
                                "id": self.parent.tag.id
                            ]
                        ]
                    ]
                    request.httpMethod = "DELETE"
                    request.allHTTPHeaderFields = [
                        "Content-Type": "application/json",
                        "Authorization": "Bearer \(appDefaults.apiKey)"
                    ]
                    request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if error == nil {
                            let statusCode = (response as! HTTPURLResponse).statusCode
                            if statusCode != 204 {
                                DispatchQueue.main.async {
                                    let notificationBanner = NotificationBanner(title: "Failed", subtitle: "\(self.parent.tag.id) was not removed from \(transaction.attributes.description).", style: .danger)
                                    notificationBanner.duration = 2
                                    notificationBanner.show()
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let notificationBanner = NotificationBanner(title: "Success", subtitle: "\(self.parent.tag.id) was removed from \(transaction.attributes.description).", style: .success)
                                    notificationBanner.duration = 2
                                    notificationBanner.show()
                                    self.parent.fetchTransactions()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                let notificationBanner = NotificationBanner(title: "Failed", subtitle: error?.localizedDescription ?? "\(self.parent.tag.id) was not removed from \(transaction.attributes.description).", style: .danger)
                                notificationBanner.duration = 2
                                notificationBanner.show()
                            }
                        }
                    }
                    .resume()
                })
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
                ac.addAction(confirmAction)
                ac.addAction(cancelAction)
                self.parent.present(ac, animated: true)
            }
        }
    }

    private let tableRefreshControl = RefreshControl(frame: .zero)
    private let searchController = SearchController(searchResultsController: nil)

    private var dateStyleObserver: NSKeyValueObservation?
    private var transactionsStatusCode: Int = 0
    private var transactions: [TransactionResource] = [] {
        didSet {
            if transactions.isEmpty {
                navigationController?.popViewController(animated: true)
            } else {
                applySnapshot(animate: isEditing)
                refreshControl?.endRefreshing()
                searchController.searchBar.placeholder = "Search \(transactions.count.description) \(transactions.count == 1 ? "Transaction" : "Transactions")"
            }
        }
    }
    private var transactionsPagination: Pagination = Pagination(prev: nil, next: nil)
    private var transactionsErrorResponse: [ErrorObject] = []
    private var transactionsError: String = ""
    private var filteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
            searchController.searchBar.text!.isEmpty || transaction.attributes.description.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    private var filteredTransactionList: Transaction {
        return Transaction(data: filteredTransactions, links: transactionsPagination)
    }
    private var categories: [CategoryResource] = []
    private var accounts: [AccountResource] = []
    
    // MARK: - View Life Cycle

    override init(style: UITableView.Style) {
        super.init(style: style)
        dataSource.parent = self
        configureProperties()
        configureNavigation()
        configureSearch()
        configureRefreshControl()
        configureTableView()
        applySnapshot()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchTransactions()
        fetchCategories()
        fetchAccounts()
    }
}

// MARK: - Configuration

private extension TransactionsByTagVC {
    private func configureProperties() {
        title = "Transactions by Tag"
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { object, change in
            self.applySnapshot()
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle())
        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.searchController = searchController
    }
    
    private func configureSearch() {
        searchController.searchBar.delegate = self
    }
    
    private func configureRefreshControl() {
        tableRefreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
    }
    
    private func configureTableView() {
        tableView.refreshControl = tableRefreshControl
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: TransactionTableViewCell.reuseIdentifier)
    }
}

// MARK: - Actions

private extension TransactionsByTagVC {
    @objc private func appMovedToForeground() {
        fetchTransactions()
        fetchCategories()
        fetchAccounts()
    }

    @objc private func refreshTransactions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchTransactions()
            self.fetchCategories()
            self.fetchAccounts()
        }
    }

    private func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, transaction in
                let cell = tableView.dequeueReusableCell(withIdentifier: TransactionTableViewCell.reuseIdentifier, for: indexPath) as! TransactionTableViewCell
                cell.transaction = transaction
                return cell
            }
        )
        dataSource.defaultRowAnimation = .fade
        return dataSource
    }

    private func applySnapshot(animate: Bool = false) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(filteredTransactionList.data, toSection: .main)
        if snapshot.itemIdentifiers.isEmpty && transactionsError.isEmpty && transactionsErrorResponse.isEmpty  {
            if transactions.isEmpty && transactionsStatusCode == 0 {
                tableView.backgroundView = {
                    let view = UIView(frame: CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: tableView.bounds.width, height: tableView.bounds.height))
                    let loadingIndicator = ActivityIndicator(style: .medium)
                    view.addSubview(loadingIndicator)
                    loadingIndicator.center(in: view)
                    loadingIndicator.startAnimating()
                    return view
                }()
            } else {
                tableView.backgroundView = {
                    let view = UIView(frame: CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: tableView.bounds.width, height: tableView.bounds.height))
                    let icon = UIImageView(image: R.image.xmarkDiamond())
                    icon.tintColor = .secondaryLabel
                    icon.width(70)
                    icon.height(64)
                    let label = UILabel()
                    label.translatesAutoresizingMaskIntoConstraints = false
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: 23)
                    label.text = "No Transactions"
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
            if !transactionsError.isEmpty {
                tableView.backgroundView = {
                    let view = UIView(frame: CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: tableView.bounds.width, height: tableView.bounds.height))
                    let label = UILabel()
                    view.addSubview(label)
                    label.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    label.center(in: view)
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = transactionsError
                    return view
                }()
            } else if !transactionsErrorResponse.isEmpty {
                tableView.backgroundView = {
                    let view = UIView(frame: CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: tableView.bounds.width, height: tableView.bounds.height))
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
                    detailLabel.textColor = .secondaryLabel
                    detailLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    detailLabel.numberOfLines = 0
                    detailLabel.text = transactionsErrorResponse.first?.detail
                    verticalStack.addArrangedSubview(titleLabel)
                    verticalStack.addArrangedSubview(detailLabel)
                    verticalStack.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    verticalStack.center(in: view)
                    verticalStack.axis = .vertical
                    verticalStack.alignment = .center
                    return view
                }()
            } else {
                if tableView.backgroundView != nil {
                    tableView.backgroundView = nil
                }
            }
        }
        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    private func fetchTransactions() {
        AF.request(UpAPI.Transactions().listTransactions, method: .get, parameters: filterTagAndPageSize100Params(tagId: tag.id), headers: [acceptJsonHeader, authorisationHeader]).responseJSON { response in
            self.transactionsStatusCode = response.response?.statusCode ?? 0
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: response.data!) {
                        self.transactionsError = ""
                        self.transactionsErrorResponse = []
                        self.transactionsPagination = decodedResponse.links
                        self.transactions = decodedResponse.data
                        if self.navigationItem.title != self.tag.id {
                            self.navigationItem.title = self.tag.id
                        }
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        self.transactionsErrorResponse = decodedResponse.errors
                        self.transactionsError = ""
                        self.transactionsPagination = Pagination(prev: nil, next: nil)
                        self.transactions = []
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                    } else {
                        self.transactionsError = "JSON Decoding Failed!"
                        self.transactionsErrorResponse = []
                        self.transactionsPagination = Pagination(prev: nil, next: nil)
                        self.transactions = []
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                    }
                case .failure:
                    self.transactionsError = response.error?.localizedDescription ?? "Unknown Error!"
                    self.transactionsErrorResponse = []
                    self.transactionsPagination = Pagination(prev: nil, next: nil)
                    self.transactions = []
                    if self.navigationItem.title != "Error" {
                        self.navigationItem.title = "Error"
                    }
            }
        }
    }

    private func fetchCategories() {
        AF.request(UpAPI.Categories().listCategories, method: .get, headers: [acceptJsonHeader, authorisationHeader]).responseJSON { response in
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
        AF.request(UpAPI.Accounts().listAccounts, method: .get, parameters: pageSize100Param, headers: [acceptJsonHeader, authorisationHeader]).responseJSON { response in
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

// MARK: - UITableViewDelegate

extension TransactionsByTagVC {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController({let vc = TransactionDetailVC(style: .grouped);vc.transaction = dataSource.itemIdentifier(for: indexPath);vc.categories = categories;vc.accounts = accounts;return vc}(), animated: true)
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove"
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
                    let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(self.tag.id)\" from \"\(transaction.attributes.description)\"?", preferredStyle: .actionSheet)
                    let confirmAction = UIAlertAction(title: "Remove", style: .destructive, handler: { [unowned self] _ in
                        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!
                        var request = URLRequest(url: url)
                        let bodyObject: [String : Any] = [
                            "data": [
                                [
                                    "type": "tags",
                                    "id": self.tag.id
                                ]
                            ]
                        ]
                        request.httpMethod = "DELETE"
                        request.allHTTPHeaderFields = [
                            "Content-Type": "application/json",
                            "Authorization": "Bearer \(appDefaults.apiKey)"
                        ]
                        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
                        URLSession.shared.dataTask(with: request) { data, response, error in
                            if error == nil {
                                let statusCode = (response as! HTTPURLResponse).statusCode
                                if statusCode != 204 {
                                    DispatchQueue.main.async {
                                        let notificationBanner = NotificationBanner(title: "Failed", subtitle: "\(self.tag.id) was not removed from \(transaction.attributes.description).", style: .danger)
                                        notificationBanner.duration = 2
                                        notificationBanner.show()
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        let notificationBanner = NotificationBanner(title: "Success", subtitle: "\(self.tag.id) was removed from \(transaction.attributes.description).", style: .success)
                                        notificationBanner.duration = 2
                                        notificationBanner.show()
                                        self.fetchTransactions()
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let notificationBanner = NotificationBanner(title: "Failed", subtitle: error?.localizedDescription ?? "\(self.tag.id) was not removed from \(transaction.attributes.description).", style: .danger)
                                    notificationBanner.duration = 2
                                    notificationBanner.show()
                                }
                            }
                        }
                        .resume()
                    })
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                    cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
                    ac.addAction(confirmAction)
                    ac.addAction(cancelAction)
                    self.present(ac, animated: true)
                }
            ])
        }
    }
}

// MARK: - UISearchBarDelegate

extension TransactionsByTagVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySnapshot(animate: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if !searchBar.text!.isEmpty {
            searchBar.text = ""
            applySnapshot(animate: true)
        }
    }
}
