import UIKit
import FLAnimatedImage
import SwiftyBeaver
import TinyConstraints
import Rswift

final class TransactionsVC: UIViewController {
    // MARK: - Properties

    private typealias Snapshot = NSDiffableDataSourceSnapshot<SortedTransactions, TransactionResource>

    private lazy var dataSource = makeDataSource()

    private lazy var filterButton = UIBarButtonItem(image: R.image.sliderHorizontal3(), menu: filterMenu())

    private let tableRefreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
        return rc
    }()

    private let tableView = UITableView(frame: .zero, style: .grouped)

    private let searchController = SearchController(searchResultsController: nil)

    private var apiKeyObserver: NSKeyValueObservation?

    private var dateStyleObserver: NSKeyValueObservation?

    private var noTransactions: Bool = false

    private var transactionsError: String = ""

    private var transactions: [TransactionResource] = [] {
        didSet {
            log.info("didSet transactions: \(transactions.count.description)")

            transactionsUpdates()
        }
    }

    private var filteredTransactions: [TransactionResource] {
        preFilteredTransactions.filter { transaction in
            searchController.searchBar.text!.isEmpty || transaction.attributes.description.localizedStandardContains(searchController.searchBar.text!)
        }
    }

    private var searchBarPlaceholder: String {
        "Search \(preFilteredTransactions.count.description) \(preFilteredTransactions.count == 1 ? "Transaction" : "Transactions")"
    }

    private var preFilteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
            (!showSettledOnly || transaction.attributes.isSettled)
            && (filter == .all || filter.rawValue == transaction.relationships.category.data?.id)
        }
    }

    private var filter: CategoryFilter = .all {
        didSet {
            log.info("didSet filter: \(categoryName(for: filter))")

            filterUpdates()
        }
    }

    private var showSettledOnly: Bool = false {
        didSet {
            log.info("didSet showSettledOnly: \(showSettledOnly.description)")

            filterUpdates()
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

    override func viewDidLoad() {
        super.viewDidLoad()
        log.debug("viewDidLoad")
        view.addSubview(tableView)
        configureTableView()
        configureProperties()
        configureNavigation()
        configureSearch()
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

extension TransactionsVC {
    private func configureTableView() {
        log.verbose("configureTableView")

        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: TransactionTableViewCell.reuseIdentifier)
        tableView.refreshControl = tableRefreshControl
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Transactions"
        definesPresentationContext = true

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { [self] object, change in
            fetchingTasks()
        }
        
        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { [self] object, change in
            DispatchQueue.main.async {
                reloadSnapshot()
            }
        }
    }

    private func configureNavigation() {
        log.verbose("configureNavigation")

        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle())
        navigationItem.searchController = searchController
        navigationItem.largeTitleDisplayMode = .always
    }

    private func configureSearch() {
        log.verbose("configureSearch")

        searchController.searchBar.delegate = self
    }
}

// MARK: - Actions

extension TransactionsVC {
    @objc private func appMovedToForeground() {
        log.verbose("appMovedToForeground")

        fetchingTasks()
    }

    @objc private func switchDateStyle() {
        log.verbose("switchDateStyle")

        if appDefaults.dateStyle == "Absolute" {
            appDefaults.dateStyle = "Relative"
        } else if appDefaults.dateStyle == "Relative" {
            appDefaults.dateStyle = "Absolute"
        }
    }

    @objc private func refreshTransactions() {
        log.verbose("refreshTransactions")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchingTasks()
        }
    }

    private func transactionsUpdates() {
        log.verbose("transactionsUpdates")

        noTransactions = transactions.isEmpty
        applySnapshot(animate: true)
        tableView.refreshControl?.endRefreshing()
        searchController.searchBar.placeholder = searchBarPlaceholder
    }

    private func filterUpdates() {
        log.verbose("filterUpdates")

        filterButton.menu = filterMenu()
        searchController.searchBar.placeholder = searchBarPlaceholder
        applySnapshot(animate: true)
    }

    private func fetchingTasks() {
        log.verbose("fetchingTasks")

        fetchTransactions()
    }

    private func filterMenu() -> UIMenu {
        return UIMenu(options: .displayInline, children: [
            UIMenu(title: "Category", image: filter == .all ? R.image.trayFull() : R.image.trayFullFill(), children: CategoryFilter.allCases.map { category in
            UIAction(title: categoryName(for: category), state: filter == category ? .on : .off) { [self] _ in
                filter = category
            }
        }),
            UIAction(title: "Settled Only", image: showSettledOnly ? R.image.checkmarkCircleFill() : R.image.checkmarkCircle(), state: showSettledOnly ? .on : .off) { [self] _ in
            showSettledOnly.toggle()
        }
        ])
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
                    label.font = R.font.circularStdMedium(size: 23)
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

    private func reloadSnapshot() {
        var snap = dataSource.snapshot()

        if #available(iOS 15.0, *) {
            snap.reconfigureItems(snap.itemIdentifiers)
        } else {
            snap.reloadItems(snap.itemIdentifiers)
        }

        dataSource.apply(snap, animatingDifferences: false)
    }

    private func fetchTransactions() {
        log.verbose("fetchTransactions")

        if #available(iOS 15.0, *) {
            async {
                do {
                    let transactions = try await Up.listTransactions()
                    
                    display(transactions)
                } catch {
                    display(error as! NetworkError)
                }
            }
        } else {
            Up.listTransactions { [self] result in
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
    
    private func display(_ transactions: [TransactionResource]) {
        log.verbose("display(transactions: \(transactions.count.description))")

        transactionsError = ""
        self.transactions = transactions

        if navigationItem.title != "Transactions" {
            navigationItem.title = "Transactions"
        }
        if navigationItem.leftBarButtonItems == nil {
            navigationItem.setLeftBarButtonItems([UIBarButtonItem(image: R.image.calendarBadgeClock(), style: .plain, target: self, action: #selector(switchDateStyle)), filterButton], animated: true)
        }
    }

    private func display(_ error: NetworkError) {
        log.verbose("display(error: \(errorString(for: error)))")

        transactionsError = errorString(for: error)
        transactions = []

        if navigationItem.title != "Error" {
            navigationItem.title = "Error"
        }
        if navigationItem.leftBarButtonItems != nil {
            navigationItem.setLeftBarButtonItems(nil, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate

extension TransactionsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.debug("tableView(didSelectRowAt indexPath: \(indexPath))")
        
        if let transaction = dataSource.itemIdentifier(for: indexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            
            navigationController?.pushViewController(TransactionDetailVC(transaction: transaction), animated: true)
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

extension TransactionsVC: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        log.debug("searchBarTextDidBeginEditing")
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        log.debug("searchBarTextDidEndEditing")
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        log.debug("searchBarSearchButtonClicked")
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        log.debug("searchBar(textDidChange searchText: \(searchText))")

        applySnapshot(animate: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        log.debug("searchBarCancelButtonClicked")

        if !searchBar.text!.isEmpty {
            searchBar.text = ""
            applySnapshot(animate: true)
        }
    }
}
