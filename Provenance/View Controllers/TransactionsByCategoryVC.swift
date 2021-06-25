import UIKit
import FLAnimatedImage
import TinyConstraints
import Rswift

class TransactionsByCategoryVC: TableViewController {
    // MARK: - Properties

    var category: CategoryResource!

    private enum Section {
        case main
    }

    private typealias DataSource = UITableViewDiffableDataSource<Section, TransactionResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, TransactionResource>

    private lazy var dataSource = makeDataSource()

    private let tableRefreshControl = RefreshControl(frame: .zero)
    private let searchController = SearchController(searchResultsController: nil)

    private var dateStyleObserver: NSKeyValueObservation?
    private var noTransactions: Bool = false
    private var transactions: [TransactionResource] = [] {
        didSet {
            noTransactions = transactions.isEmpty
            applySnapshot()
            refreshControl?.endRefreshing()
            searchController.searchBar.placeholder = "Search \(transactions.count.description) \(transactions.count == 1 ? "Transaction" : "Transactions")"
        }
    }
    private var transactionsPagination: Pagination = Pagination(prev: nil, next: nil)
    private var transactionsError: String = ""
    private var filteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
            searchController.searchBar.text!.isEmpty || transaction.attributes.description.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    private var filteredTransactionList: Transaction {
        Transaction(data: filteredTransactions, links: transactionsPagination)
    }
    private var categories: [CategoryResource] = []
    private var accounts: [AccountResource] = []
    
    // MARK: - View Life Cycle
    
    override init(style: UITableView.Style) {
        super.init(style: style)
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
        super.viewWillAppear(animated)
        fetchTransactions()
        fetchAccounts()
        fetchCategories()
    }
}

// MARK: - Configuration

private extension TransactionsByCategoryVC {
    private func configureProperties() {
        title = "Transactions by Category"
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { object, change in
            self.applySnapshot()
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle())
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

private extension TransactionsByCategoryVC {
    @objc private func appMovedToForeground() {
        fetchTransactions()
        fetchAccounts()
        fetchCategories()
    }

    @objc private func refreshTransactions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchTransactions()
            self.fetchAccounts()
            self.fetchCategories()
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
        if snapshot.itemIdentifiers.isEmpty && transactionsError.isEmpty {
            if transactions.isEmpty && !noTransactions {
                tableView.backgroundView = {
                    let view = UIView(frame: CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: tableView.bounds.width, height: tableView.bounds.height))
                    let loadingIndicator = FLAnimatedImageView()
                    loadingIndicator.animatedImage = upZapSpinTransparentBackground
                    loadingIndicator.width(100)
                    loadingIndicator.height(100)
                    view.addSubview(loadingIndicator)
                    loadingIndicator.center(in: view)
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
            } else {
                if tableView.backgroundView != nil {
                    tableView.backgroundView = nil
                }
            }
        }
        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    private func fetchTransactions() {
        upApi.listTransactions(filterBy: category) { result in
            switch result {
                case .success(let transactions):
                    DispatchQueue.main.async {
                        self.transactionsError = ""
                        self.transactions = transactions
                        if self.navigationItem.title != self.category.attributes.name {
                            self.navigationItem.title = self.category.attributes.name
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.transactionsError = errorString(for: error)
                        self.transactions = []
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                    }
            }
        }
    }

    private func fetchAccounts() {
        upApi.listAccounts { result in
            switch result {
                case .success(let accounts):
                    DispatchQueue.main.async {
                        self.accounts = accounts
                    }
                case .failure(let error):
                    print(errorString(for: error))
            }
        }
    }

    private func fetchCategories() {
        upApi.listCategories { result in
            switch result {
                case .success(let categories):
                    DispatchQueue.main.async {
                        self.categories = categories
                    }
                case .failure(let error):
                    print(errorString(for: error))
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension TransactionsByCategoryVC {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController({let vc = TransactionDetailVC(style: .insetGrouped);vc.transaction = dataSource.itemIdentifier(for: indexPath);vc.accounts = accounts;vc.categories = categories;return vc}(), animated: true)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let transaction = dataSource.itemIdentifier(for: indexPath)!
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy Description", image: R.image.textAlignright()) { action in
                UIPasteboard.general.string = transaction.attributes.description
            },
                UIAction(title: "Copy Creation Date", image: R.image.calendarCircle()) { action in
                UIPasteboard.general.string = transaction.attributes.creationDate
            },
                UIAction(title: "Copy Amount", image: R.image.dollarsignCircle()) { action in
                UIPasteboard.general.string = transaction.attributes.amount.valueShort
            }
            ])
        }
    }
}

// MARK: - UISearchBarDelegate

extension TransactionsByCategoryVC: UISearchBarDelegate {
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
