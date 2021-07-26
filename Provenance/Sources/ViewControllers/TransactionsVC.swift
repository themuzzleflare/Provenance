import UIKit
import FLAnimatedImage
import SwiftyBeaver
import TinyConstraints
import Rswift

final class TransactionsVC: UIViewController {
    // MARK: - Properties

    private typealias Snapshot = NSDiffableDataSourceSnapshot<SortedTransactions, TransactionResource>

    private lazy var dataSource = makeDataSource()

    private lazy var filterBarButtonItem = UIBarButtonItem(
        image: R.image.sliderHorizontal3(),
        menu: filterMenu()
    )

    private lazy var searchController: UISearchController = {
        let sc = SearchController(searchResultsController: nil)

        sc.searchBar.delegate = self

        return sc
    }()

    private let tableRefreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()

        rc.addTarget(
            self,
            action: #selector(refreshTransactions),
            for: .valueChanged
        )

        return rc
    }()

    private let tableView = UITableView(
        frame: .zero,
        style: .grouped
    )

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
        return preFilteredTransactions.filter {
            (transaction) in
            searchController.searchBar.text!.isEmpty ||
            transaction.attributes.transactionDescription.localizedStandardContains(searchController.searchBar.text!)
        }
    }

    private var searchBarPlaceholder: String {
        return "Search \(preFilteredTransactions.count.description) \(preFilteredTransactions.count == 1 ? "Transaction" : "Transactions")"
    }

    private var preFilteredTransactions: [TransactionResource] {
        return transactions.filter {
            (transaction) in
            (!showSettledOnly || transaction.attributes.isSettled) &&
            (filter == .all || filter.rawValue == transaction.relationships.category.data?.id)
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
        return Dictionary(
            grouping: filteredTransactions,
            by: { $0.attributes.createdAtDate }
        )
    }

    private var sortedTransactions: [(key: Date, value: [TransactionResource])] {
        return groupedTransactions.sorted { $0.key > $1.key }
    }

    private var sections: [SortedTransactions] = []

    // UITableViewDiffableDataSource
    private class DataSource: UITableViewDiffableDataSource<SortedTransactions, TransactionResource> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            guard let firstTransaction = itemIdentifier(
                for: IndexPath(
                    item: 0,
                    section: section
                )
            ) else { return nil }

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

        tableView.register(
            TransactionTableViewCell.self,
            forCellReuseIdentifier: TransactionTableViewCell.reuseIdentifier
        )

        tableView.refreshControl = tableRefreshControl

        tableView.autoresizingMask = [
            .flexibleHeight,
            .flexibleWidth
        ]
    }

    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Transactions"
        definesPresentationContext = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        apiKeyObserver = appDefaults.observe(
            \.apiKey,
            options: .new,
            changeHandler: {
                [self] (_, _) in
                fetchingTasks()
            }
        )

        dateStyleObserver = appDefaults.observe(
            \.dateStyle,
            options: .new,
            changeHandler: {
                [self] (_, _) in
                DispatchQueue.main.async { reloadSnapshot() }
            }
        )
    }

    private func configureNavigation() {
        log.verbose("configureNavigation")

        navigationItem.title = "Loading"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle())
        navigationItem.searchController = searchController
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

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1,
            execute: {
                [self] in
                fetchingTasks()
            }
        )
    }

    private func transactionsUpdates() {
        log.verbose("transactionsUpdates")

        noTransactions = transactions.isEmpty
        applySnapshot()
        tableView.refreshControl?.endRefreshing()
        searchController.searchBar.placeholder = searchBarPlaceholder
    }

    private func filterUpdates() {
        log.verbose("filterUpdates")

        filterBarButtonItem.menu = filterMenu()
        searchController.searchBar.placeholder = searchBarPlaceholder
        applySnapshot()
    }

    private func fetchingTasks() {
        log.verbose("fetchingTasks")

        fetchTransactions()
    }

    private func filterMenu() -> UIMenu {
        return UIMenu(
            children: [
                UIMenu(
                    title: "Category",
                    image: filter == .all ? R.image.trayFull() : R.image.trayFullFill(),
                    children: CategoryFilter.allCases.map {
                        (category) in
                        UIAction(
                            title: categoryName(for: category),
                            state: filter == category ? .on : .off,
                            handler: {
                                [self] (_) in
                                filter = category
                            }
                        )
                    }
                ),
                UIAction(
                    title: "Settled Only",
                    image: showSettledOnly ? R.image.checkmarkCircleFill() : R.image.checkmarkCircle(),
                    state: showSettledOnly ? .on : .off,
                    handler: {
                        [self] (_) in
                        showSettledOnly.toggle()
                    }
                )
            ]
        )
    }

    private func makeDataSource() -> DataSource {
        log.verbose("makeDataSource")

        return DataSource(
            tableView: tableView,
            cellProvider: {
                (tableView, indexPath, transaction) in
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: TransactionTableViewCell.reuseIdentifier,
                    for: indexPath
                ) as? TransactionTableViewCell else {
                    fatalError("Unable to dequeue reusable cell with identifier: \(TransactionTableViewCell.reuseIdentifier)")
                }

                cell.transaction = transaction

                return cell
            }
        )
    }

    private func applySnapshot(animate: Bool = true) {
        log.verbose("applySnapshot(animate: \(animate.description))")

        sections = sortedTransactions.map {
            SortedTransactions(
                id: $0.key,
                transactions: $0.value
            )
        }

        var snapshot = Snapshot()

        snapshot.appendSections(sections)

        sections.forEach {
            snapshot.appendItems(
                $0.transactions,
                toSection: $0
            )
        }

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

                    let vStack = UIStackView(
                        arrangedSubviews: [
                            icon,
                            label
                        ]
                    )

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
                if tableView.backgroundView != nil { tableView.backgroundView = nil }
            }
        }

        dataSource.apply(
            snapshot,
            animatingDifferences: animate
        )
    }

    private func reloadSnapshot() {
        log.verbose("reloadSnapshot")

        var snap = dataSource.snapshot()

        snap.reloadItems(snap.itemIdentifiers)

        dataSource.apply(
            snap,
            animatingDifferences: false
        )
    }

    private func fetchTransactions() {
        log.verbose("fetchTransactions")

        UpFacade.listTransactions {
            [self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let transactions): display(transactions)
                case .failure(let error): display(error)
                }
            }
        }
    }

    private func display(_ transactions: [TransactionResource]) {
        log.verbose("display(transactions: \(transactions.count.description))")

        transactionsError = ""

        self.transactions = transactions

        if navigationItem.title != "Transactions" { navigationItem.title = "Transactions" }

        if navigationItem.leftBarButtonItems == nil {
            let barButtonItems = [
                UIBarButtonItem(
                    image: R.image.calendarBadgeClock(),
                    style: .plain,
                    target: self,
                    action: #selector(switchDateStyle)
                ),
                filterBarButtonItem
            ]

            navigationItem.setLeftBarButtonItems(
                barButtonItems,
                animated: true
            )
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
            navigationItem.setLeftBarButtonItems(
                nil,
                animated: true
            )
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

        tableView.deselectRow(
            at: indexPath,
            animated: true
        )

        if let transaction = dataSource.itemIdentifier(for: indexPath) {
            navigationController?.pushViewController(
                TransactionDetailVC(transaction: transaction),
                animated: true
            )
        }
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let transaction = dataSource.itemIdentifier(for: indexPath)
        else { return nil }

        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil,
            actionProvider: {
                (_) in
                UIMenu(
                    children: [
                        UIAction(
                            title: "Copy Description",
                            image: R.image.textAlignright(),
                            handler: {
                                (_) in
                                UIPasteboard.general.string = transaction.attributes.transactionDescription
                            }
                        ),
                        UIAction(
                            title: "Copy Creation Date",
                            image: R.image.calendarCircle(),
                            handler: {
                                (_) in
                                UIPasteboard.general.string = transaction.attributes.creationDate
                            }
                        ),
                        UIAction(
                            title: "Copy Amount",
                            image: R.image.dollarsignCircle(),
                            handler: {
                                (_) in
                                UIPasteboard.general.string = transaction.attributes.amount.valueShort
                            }
                        )
                    ]
                )
            }
        )
    }
}

// MARK: - UISearchBarDelegate

extension TransactionsVC: UISearchBarDelegate {
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
