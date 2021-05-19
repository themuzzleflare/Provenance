import UIKit
import WidgetKit
import Alamofire
import TinyConstraints
import Rswift

class TransactionsVC: TableViewController {
    // MARK: - Properties

    private enum Section {
        case main
    }

    private typealias DataSource = UITableViewDiffableDataSource<Section, TransactionResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, TransactionResource>

    private lazy var dataSource = makeDataSource()
    private lazy var filterButton = UIBarButtonItem(image: R.image.sliderHorizontal3(), menu: filterMenu())

    private let tableRefreshControl = RefreshControl(frame: .zero)
    private let searchController = SearchController(searchResultsController: nil)

    private var dateStyleObserver: NSKeyValueObservation?
    private var searchBarPlaceholder: String {
        "Search \(preFilteredTransactions.count.description) \(preFilteredTransactions.count == 1 ? "Transaction" : "Transactions")"
    }
    private var transactionsStatusCode: Int = 0
    private var transactions: [TransactionResource] = [] {
        didSet {
            applySnapshot()
            refreshControl?.endRefreshing()
            WidgetCenter.shared.reloadAllTimelines()
            searchController.searchBar.placeholder = searchBarPlaceholder
        }
    }
    private var transactionsPagination: Pagination = Pagination(prev: nil, next: nil)
    private var transactionsErrorResponse: [ErrorObject] = []
    private var transactionsError: String = ""
    private var preFilteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
            (!showSettledOnly || transaction.attributes.isSettled)
                && (filter == .all || filter.rawValue == transaction.relationships.category.data?.id)
        }
    }
    private var filteredTransactions: [TransactionResource] {
        preFilteredTransactions.filter { transaction in
            searchController.searchBar.text!.isEmpty || transaction.attributes.description.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    private var filteredTransactionList: Transaction {
        return Transaction(data: filteredTransactions, links: transactionsPagination)
    }
    private var categories: [CategoryResource] = []
    private var accounts: [AccountResource] = []
    private var filter: FilterCategory = .all {
        didSet {
            filterButton.menu = filterMenu()
            searchController.searchBar.placeholder = searchBarPlaceholder
            applySnapshot(animate: true)
        }
    }
    private var showSettledOnly: Bool = false {
        didSet {
            filterButton.menu = filterMenu()
            searchController.searchBar.placeholder = searchBarPlaceholder
            applySnapshot(animate: true)
        }
    }

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureProperties()
        configureNavigation()
        configureSearch()
        configureRefreshControl()
        configureTableView()
        applySnapshot()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchTransactions()
        fetchAccounts()
        fetchCategories()
    }
}

// MARK: - Configuration

private extension TransactionsVC {
    private func configureProperties() {
        title = "Transactions"
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { object, change in
            self.applySnapshot()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle(), style: .plain, target: self, action: nil)
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

private extension TransactionsVC {
    @objc private func appMovedToForeground() {
        fetchTransactions()
        fetchAccounts()
        fetchCategories()
    }

    @objc private func switchDateStyle() {
        if appDefaults.dateStyle == "Absolute" {
            appDefaults.dateStyle = "Relative"
        } else if appDefaults.dateStyle == "Relative" {
            appDefaults.dateStyle = "Absolute"
        }
    }

    @objc private func refreshTransactions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchTransactions()
            self.fetchCategories()
            self.fetchAccounts()
        }
    }

    private func filterMenu() -> UIMenu {
        return UIMenu(image: R.image.sliderHorizontal3(), options: .displayInline, children: [
            UIMenu(title: "Category", image: R.image.arrowUpArrowDownCircle(), children: FilterCategory.allCases.map { category in
                UIAction(title: categoryNameTransformed(category), state: filter == category ? .on : .off) { _ in
                    self.filter = category
                }
            }),
            UIAction(title: "Settled Only", image: R.image.checkmarkCircle(), state: showSettledOnly ? .on : .off) { _ in
                self.showSettledOnly.toggle()
            }
        ])
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
                    let label = UILabel()
                    view.addSubview(label)
                    label.center(in: view)
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.text = "No Transactions"
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
        AF.request(UpAPI.Transactions().listTransactions, method: .get, parameters: pageSize100Param, headers: [acceptJsonHeader, authorisationHeader]).responseJSON { response in
            self.transactionsStatusCode = response.response?.statusCode ?? 0
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: response.data!) {
                        self.transactionsError = ""
                        self.transactionsErrorResponse = []
                        self.transactionsPagination = decodedResponse.links
                        self.transactions = decodedResponse.data
                        if self.navigationItem.title != "Transactions" {
                            self.navigationItem.title = "Transactions"
                        }
                        if self.navigationItem.leftBarButtonItems == nil {
                            self.navigationItem.setLeftBarButtonItems([UIBarButtonItem(image: R.image.arrowUpArrowDown(), style: .plain, target: self, action: #selector(self.switchDateStyle)), self.filterButton], animated: true)
                        }
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        self.transactionsErrorResponse = decodedResponse.errors
                        self.transactionsError = ""
                        self.transactionsPagination = Pagination(prev: nil, next: nil)
                        self.transactions = []
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        if self.navigationItem.leftBarButtonItems != nil {
                            self.navigationItem.setLeftBarButtonItems(nil, animated: true)
                        }
                    } else {
                        self.transactionsError = "JSON Decoding Failed!"
                        self.transactionsErrorResponse = []
                        self.transactionsPagination = Pagination(prev: nil, next: nil)
                        self.transactions = []
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        if self.navigationItem.leftBarButtonItems != nil {
                            self.navigationItem.setLeftBarButtonItems(nil, animated: true)
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
                    if self.navigationItem.leftBarButtonItems != nil {
                        self.navigationItem.setLeftBarButtonItems(nil, animated: true)
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

extension TransactionsVC {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController({let vc = TransactionDetailVC(style: .grouped);vc.transaction = dataSource.itemIdentifier(for: indexPath);vc.categories = categories;vc.accounts = accounts;return vc}(), animated: true)
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
                }
            ])
        }
    }
}

// MARK: - UISearchBarDelegate

extension TransactionsVC: UISearchBarDelegate {
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
