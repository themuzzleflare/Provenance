import UIKit
import FLAnimatedImage
import TinyConstraints
import Rswift

final class TransactionsByAccountVC: UIViewController {
    // MARK: - Properties

    private var account: AccountResource {
        didSet {
            tableView.tableHeaderView = {
                let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 117))

                let balanceLabel = UILabel()
                let displayNameLabel = UILabel()
                let verticalStack = UIStackView(arrangedSubviews: [balanceLabel, displayNameLabel])

                view.addSubview(verticalStack)

                verticalStack.centerInSuperview()
                verticalStack.axis = .vertical
                verticalStack.alignment = .center

                balanceLabel.translatesAutoresizingMaskIntoConstraints = false
                balanceLabel.textColor = R.color.accentColor()
                balanceLabel.font = R.font.circularStdBold(size: 32)
                balanceLabel.textAlignment = .center
                balanceLabel.numberOfLines = 0
                balanceLabel.text = account.attributes.balance.valueShort

                displayNameLabel.translatesAutoresizingMaskIntoConstraints = false
                displayNameLabel.textColor = .secondaryLabel
                displayNameLabel.font = R.font.circularStdBook(size: 14)
                displayNameLabel.textAlignment = .center
                displayNameLabel.numberOfLines = 0
                displayNameLabel.text = account.attributes.displayName

                return view
            }()
        }
    }

    private enum Section {
        case main
    }

    private typealias DataSource = UITableViewDiffableDataSource<Section, TransactionResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, TransactionResource>

    private lazy var dataSource = makeDataSource()

    private let transactionsPagination = Pagination(prev: nil, next: nil)
    private let searchController = SearchController(searchResultsController: nil)
    private let tableRefreshControl = RefreshControl(frame: .zero)
    private let tableView = UITableView(frame: .zero, style: .grouped)

    private var dateStyleObserver: NSKeyValueObservation?
    private var noTransactions: Bool = false

    private var transactions: [TransactionResource] = [] {
        didSet {
            transactionsUpdates()
        }
    }

    private var transactionsError: String = ""

    private var filteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
            searchController.searchBar.text!.isEmpty || transaction.attributes.description.localizedStandardContains(searchController.searchBar.text!)
        }
    }

    private var filteredTransactionList: Transaction {
        Transaction(data: filteredTransactions, links: transactionsPagination)
    }
    
    // MARK: - Life Cycle

    init(account: AccountResource) {
        self.account = account

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)

        configureProperties()
        configureNavigation()
        configureSearch()
        configureRefreshControl()
        configureTableView()

        applySnapshot()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchingTasks()
    }
}

// MARK: - Configuration

private extension TransactionsByAccountVC {
    private func configureProperties() {
        title = "Transactions by Account"
        definesPresentationContext = true

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { [self] object, change in
            DispatchQueue.main.async {
                applySnapshot()
            }
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle())
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.infoCircle(), style: .plain, target: self, action: #selector(openAccountInfo))
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func configureSearch() {
        searchController.searchBar.delegate = self
    }
    
    private func configureRefreshControl() {
        tableRefreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
    }
    
    private func configureTableView() {
        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: TransactionTableViewCell.reuseIdentifier)
        tableView.refreshControl = tableRefreshControl
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}

// MARK: - Actions

private extension TransactionsByAccountVC {
    @objc private func appMovedToForeground() {
        fetchingTasks()
    }

    @objc private func openAccountInfo() {
        present(NavigationController(rootViewController: AccountDetailVC(account: account, transaction: transactions.first)), animated: true)
    }

    @objc private func refreshTransactions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchingTasks()
        }
    }

    private func fetchingTasks() {
        fetchAccount()
        fetchTransactions()
    }

    private func transactionsUpdates() {
        noTransactions = transactions.isEmpty
        applySnapshot()
        tableView.refreshControl?.endRefreshing()
        searchController.searchBar.placeholder = "Search \(transactions.count.description) \(transactions.count == 1 ? "Transaction" : "Transactions")"
    }

    private func makeDataSource() -> DataSource {
        DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, transaction in
                let cell = tableView.dequeueReusableCell(withIdentifier: TransactionTableViewCell.reuseIdentifier, for: indexPath) as! TransactionTableViewCell

                cell.transaction = transaction

                return cell
            }
        )
    }

    private func applySnapshot(animate: Bool = false) {
        var snapshot = Snapshot()

        snapshot.appendSections([.main])
        snapshot.appendItems(filteredTransactionList.data, toSection: .main)

        if snapshot.itemIdentifiers.isEmpty && transactionsError.isEmpty {
            if transactions.isEmpty && !noTransactions {
                tableView.backgroundView = {
                    let view = UIView(frame: tableView.bounds)

                    let loadingIndicator = FLAnimatedImageView()

                    view.addSubview(loadingIndicator)

                    loadingIndicator.centerInSuperview()
                    loadingIndicator.width(100)
                    loadingIndicator.height(100)
                    loadingIndicator.animatedImage = upZapSpinTransparentBackground

                    return view
                }()
            } else {
                tableView.backgroundView = {
                    let view = UIView(frame: tableView.bounds)

                    let icon = UIImageView(image: R.image.xmarkDiamond())

                    icon.width(70)
                    icon.height(64)
                    icon.tintColor = .secondaryLabel

                    let label = UILabel()

                    label.translatesAutoresizingMaskIntoConstraints = false
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: 23)
                    label.text = "No Transactions"

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
            if !transactionsError.isEmpty {
                tableView.backgroundView = {
                    let view = UIView(frame: tableView.bounds)

                    let label = UILabel()

                    view.addSubview(label)

                    label.horizontalToSuperview(insets: .horizontal(16))
                    label.centerInSuperview()
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

    private func fetchAccount() {
        if #available(iOS 15.0, *) {
            async {
                do {
                    let account = try await Up.retrieveAccount(for: account)

                    display(account)
                } catch {
                    print(errorString(for: error as! NetworkError))
                }
            }
        } else {
            Up.retrieveAccount(for: account) { [self] result in
                DispatchQueue.main.async {
                    switch result {
                        case .success(let account):
                            display(account)
                        case .failure(let error):
                            print(errorString(for: error))
                    }
                }
            }
        }
    }

    private func fetchTransactions() {
        if #available(iOS 15.0, *) {
            async {
                do {
                    let transactions = try await Up.listTransactions(filterBy: account)

                    display(transactions)
                } catch {
                    display(error as! NetworkError)
                }
            }
        } else {
            Up.listTransactions(filterBy: account) { [self] result in
                DispatchQueue.main.async {
                    switch result {
                        case .success(let transactions):
                            display(transactions)
                        case .failure(let error):
                            display(error)
                    }
                }
            }
        }
    }

    private func display(_ account: AccountResource) {
        self.account = account
    }
    
    private func display(_ transactions: [TransactionResource]) {
        transactionsError = ""
        self.transactions = transactions

        if navigationItem.title != account.attributes.displayName {
            navigationItem.title = account.attributes.displayName
        }
    }

    private func display(_ error: NetworkError) {
        transactionsError = errorString(for: error)
        transactions = []

        if navigationItem.title != "Error" {
            navigationItem.title = "Error"
        }
    }
}

// MARK: - UITableViewDelegate

extension TransactionsByAccountVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let transactionId = dataSource.itemIdentifier(for: indexPath) {
            navigationController?.pushViewController(TransactionDetailCVC(transaction: transactionId), animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let transaction = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

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

extension TransactionsByAccountVC: UISearchBarDelegate {
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
