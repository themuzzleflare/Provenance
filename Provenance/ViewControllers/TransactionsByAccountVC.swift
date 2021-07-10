import UIKit
import FLAnimatedImage
import SwiftyBeaver
import TinyConstraints
import Rswift

final class TransactionsByAccountVC: UIViewController {
    // MARK: - Properties

    private var account: AccountResource {
        didSet {
            log.info("didSet account: \(account.attributes.displayName)")

            if !searchController.isFirstResponder && searchController.searchBar.text!.isEmpty {
                setTableHeaderView()
            }
        }
    }

    private typealias Snapshot = NSDiffableDataSourceSnapshot<SortedTransactions, TransactionResource>

    private lazy var dataSource = makeDataSource()

    private let searchController = SearchController(searchResultsController: nil)

    private let tableRefreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return rc
    }()

    private let tableView = UITableView(frame: .zero, style: .grouped)

    private var dateStyleObserver: NSKeyValueObservation?
    
    private var noTransactions: Bool = false

    private var transactions: [TransactionResource] = [] {
        didSet {
            log.info("didSet transactions: \(transactions.count.description)")

            transactionsUpdates()
        }
    }

    private var transactionsError: String = ""

    private var filteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
            searchController.searchBar.text!.isEmpty || transaction.attributes.description.localizedStandardContains(searchController.searchBar.text!)
        }
    }

    private var groupedTransactions: [Date: [TransactionResource]] {
        Dictionary(
            grouping: filteredTransactions,
            by: { $0.attributes.createdAtDate }
        )
    }

    private var sortedTransactions: Array<(key: Date, value: Array<TransactionResource>)> {
        groupedTransactions.sorted { $0.key > $1.key }
    }

    private var sections: [SortedTransactions] = []

    // UITableViewDiffableDataSource
    private class DataSource: UITableViewDiffableDataSource<SortedTransactions, TransactionResource> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            guard let firstTransaction = itemIdentifier(for: IndexPath(item: 0, section: section)) else {
                return nil
            }

            return firstTransaction.attributes.creationDayMonthYear
        }
    }
    
    // MARK: - Life Cycle

    init(account: AccountResource) {
        self.account = account
        super.init(nibName: nil, bundle: nil)
        log.debug("init(account: \(account.attributes.displayName))")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        log.debug("deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        log.debug("viewDidLoad")
        view.addSubview(tableView)
        configureProperties()
        configureNavigation()
        configureSearch()
        configureTableView()
        applySnapshot()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        log.debug("viewDidLayoutSubviews")
        tableView.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        log.debug("viewWillAppear(animated: \(animated.description))")
        fetchingTasks()
    }
}

// MARK: - Configuration

private extension TransactionsByAccountVC {
    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Transactions by Account"
        definesPresentationContext = true

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { [self] object, change in
            DispatchQueue.main.async {
                reloadSnapshot()
            }
        }
    }
    
    private func configureNavigation() {
        log.verbose("configureNavigation")
        navigationItem.title = "Loading"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle())
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.infoCircle(), style: .plain, target: self, action: #selector(openAccountInfo))
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func configureSearch() {
        log.verbose("configureSearch")

        searchController.searchBar.delegate = self
    }
    
    private func configureTableView() {
        log.verbose("configureTableView")

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
        log.verbose("appMovedToForeground")

        fetchingTasks()
    }

    @objc private func openAccountInfo() {
        log.verbose("openAccountInfo")

        present(NavigationController(rootViewController: AccountDetailVC(account: account, transaction: transactions.first)), animated: true)
    }

    @objc private func refreshData() {
        log.verbose("refreshData")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchingTasks()
        }
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

    private func setTableHeaderView() {
        tableView.tableHeaderView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 117))

            let balanceLabel = SRCopyableLabel()
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

    private func fetchingTasks() {
        log.verbose("fetchingTasks")

        fetchAccount()
        fetchTransactions()
    }

    private func transactionsUpdates() {
        log.verbose("transactionsUpdates")

        noTransactions = transactions.isEmpty
        applySnapshot()
        tableView.refreshControl?.endRefreshing()
        searchController.searchBar.placeholder = "Search \(transactions.count.description) \(transactions.count == 1 ? "Transaction" : "Transactions")"
    }

    private func makeDataSource() -> DataSource {
        log.verbose("makeDataSource")

        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, transaction in
            let cell = tableView.dequeueReusableCell(withIdentifier: TransactionTableViewCell.reuseIdentifier, for: indexPath) as! TransactionTableViewCell

            cell.transaction = transaction

            return cell
        }
        )
        dataSource.defaultRowAnimation = .automatic
        return dataSource
    }

    private func applySnapshot(animate: Bool = true) {
        log.verbose("applySnapshot(animate: \(animate.description))")

        sections = sortedTransactions.map { SortedTransactions(id: $0.key, transactions: $0.value) }

        var snapshot = Snapshot()

        snapshot.appendSections(sections)
        sections.forEach { snapshot.appendItems($0.transactions, toSection: $0) }

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
        log.verbose("fetchAccount")

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
        log.verbose("fetchTransactions")

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
        log.verbose("display(account: \(account.attributes.displayName))")

        self.account = account
    }
    
    private func display(_ transactions: [TransactionResource]) {
        log.verbose("display(transactions: \(transactions.count.description))")

        transactionsError = ""
        self.transactions = transactions

        if navigationItem.title != account.attributes.displayName {
            navigationItem.title = account.attributes.displayName
        }
    }

    private func display(_ error: NetworkError) {
        log.verbose("display(error: \(errorString(for: error)))")

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
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.debug("tableView(didSelectRowAt indexPath: \(indexPath))")

        tableView.deselectRow(at: indexPath, animated: true)

        if let transactionId = dataSource.itemIdentifier(for: indexPath) {
            navigationController?.pushViewController(TransactionDetailVC(transaction: transactionId), animated: true)
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
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        tableView.tableHeaderView = nil
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if searchBar.text!.isEmpty {
            setTableHeaderView()
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        log.debug("searchBar(textDidChange searchText: \(searchText))")

        applySnapshot(animate: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        log.debug("searchBarCancelButtonClicked")

        if !searchBar.text!.isEmpty {
            setTableHeaderView()
            searchBar.text = ""
            applySnapshot(animate: true)
        }
    }
}
