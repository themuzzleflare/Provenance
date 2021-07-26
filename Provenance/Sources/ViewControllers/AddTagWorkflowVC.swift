import UIKit
import FLAnimatedImage
import SwiftyBeaver
import TinyConstraints
import Rswift

final class AddTagWorkflowVC: UIViewController {
    // MARK: - Properties

    private typealias Snapshot = NSDiffableDataSourceSnapshot<SortedTransactions, TransactionResource>

    private lazy var dataSource = makeDataSource()

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

    private var dateStyleObserver: NSKeyValueObservation?

    private var noTransactions: Bool = false

    private var transactions: [TransactionResource] = [] {
        didSet {
            log.info("didSet transactions: \(transactions.count.description)")

            noTransactions = transactions.isEmpty

            applySnapshot()

            tableView.refreshControl?.endRefreshing()

            searchController.searchBar.placeholder = "Search \(transactions.count.description) \(transactions.count == 1 ? "Transaction" : "Transactions")"
        }
    }

    private var transactionsError: String = ""

    private var filteredTransactions: [TransactionResource] {
        return transactions.filter { transaction in
            searchController.searchBar.text!.isEmpty
                || transaction.attributes.transactionDescription
                .localizedStandardContains(searchController.searchBar.text!)
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

        configureProperties()

        configureNavigation()

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

        fetchTransactions()
    }
}

// MARK: - Configuration

private extension AddTagWorkflowVC {
    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Transaction Selection"

        definesPresentationContext = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) {
            [self] (_, _) in
            DispatchQueue.main.async {
                reloadSnapshot()
            }
        }
    }

    private func configureNavigation() {
        log.verbose("configureNavigation")

        navigationItem.title = "Loading"

        navigationItem.largeTitleDisplayMode = .never

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeWorkflow)
        )

        navigationItem.searchController = searchController

        navigationItem.hidesSearchBarWhenScrolling = false

        navigationItem.backButtonDisplayMode = .minimal
    }

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
}

// MARK: - Actions

private extension AddTagWorkflowVC {
    @objc private func appMovedToForeground() {
        log.verbose("appMovedToForeground")

        fetchTransactions()
    }

    @objc private func refreshTransactions() {
        log.verbose("fetchTransactions")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            [self] in
            fetchTransactions()
        }
    }

    @objc private func closeWorkflow() {
        log.verbose("closeWorkflow")

        navigationController?.dismiss(animated: true)
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

    private func makeDataSource() -> DataSource {
        log.verbose("makeDataSource")

        let dataSource = DataSource(
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

        dataSource.defaultRowAnimation = .middle

        return dataSource
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
                    label.font = R.font.circularStdBook(size: 23)
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
                if tableView.backgroundView != nil {
                    tableView.backgroundView = nil
                }
            }
        }

        dataSource.apply(
            snapshot,
            animatingDifferences: animate
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

        if navigationItem.title != "Select Transaction" {
            navigationItem.title = "Select Transaction"
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

extension AddTagWorkflowVC: UITableViewDelegate {
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
                AddTagWorkflowTwoVC(transaction: transaction),
                animated: true
            )
        }
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let transaction = dataSource.itemIdentifier(for: indexPath) else { return nil }

        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil
        ) {
            (_) in
            UIMenu(
                children: [
                    UIAction(
                        title: "Copy Description",
                        image: R.image.textAlignright()
                    ) {
                        (_) in
                        UIPasteboard.general.string = transaction.attributes.transactionDescription
                    },
                    UIAction(
                        title: "Copy Creation Date",
                        image: R.image.calendarCircle()
                    ) {
                        (_) in
                        UIPasteboard.general.string = transaction.attributes.creationDate
                    },
                    UIAction(
                        title: "Copy Amount",
                        image: R.image.dollarsignCircle()
                    ) {
                        (_) in
                        UIPasteboard.general.string = transaction.attributes.amount.valueShort
                    }
                ]
            )
        }
    }
}

// MARK: - UISearchBarDelegate

extension AddTagWorkflowVC: UISearchBarDelegate {
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
