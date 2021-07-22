import UIKit
import FLAnimatedImage
import NotificationBannerSwift
import SwiftyBeaver
import TinyConstraints
import Rswift

final class TransactionsByTagVC: UIViewController {
    // MARK: - Properties
    
    private var tag: TagResource
    
    private typealias Snapshot = NSDiffableDataSourceSnapshot<SortedTransactions, TransactionResource>
    
    private lazy var dataSource = makeDataSource()

    private lazy var searchController: UISearchController = {
        let sc = SearchController(searchResultsController: nil)
        sc.searchBar.delegate = self
        return sc
    }()
    
    private let tableRefreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
        return rc
    }()

    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    private var dateStyleObserver: NSKeyValueObservation?
    
    private var noTransactions: Bool = false
    
    private var transactions: [TransactionResource] = [] {
        didSet {
            log.info("didSet transactions: \(transactions.count.description)")
            
            noTransactions = transactions.isEmpty
            
            if transactions.isEmpty {
                navigationController?.popViewController(animated: true)
            } else {
                applySnapshot()
                tableView.refreshControl?.endRefreshing()
                searchController.searchBar.placeholder = "Search \(transactions.count.description) \(transactions.count == 1 ? "Transaction" : "Transactions")"
            }
        }
    }
    
    private var transactionsError: String = ""
    
    private var filteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
            searchController.searchBar.text!.isEmpty || transaction.attributes.transactionDescription.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    
    private var groupedTransactions: [Date: [TransactionResource]] {
        Dictionary(
            grouping: filteredTransactions,
            by: { $0.attributes.createdAtDate }
        )
    }
    
    private var sortedTransactions: Array<(key: Date, value: Array<TransactionResource>)> {
        return groupedTransactions.sorted { $0.key > $1.key }
    }
    
    private var sections: [SortedTransactions] = []
    
    // UITableViewDiffableDataSource
    private class DataSource: UITableViewDiffableDataSource<SortedTransactions, TransactionResource> {
        weak var parent: TransactionsByTagVC! = nil
        
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            guard let firstTransaction = itemIdentifier(for: IndexPath(item: 0, section: section)) else { return nil }
            
            return firstTransaction.attributes.creationDayMonthYear
        }
        
        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            log.debug("tableView(commit editingStyle: \(editingStyle.rawValue), forRowAt indexPath: \(indexPath))")
            
            guard let transaction = itemIdentifier(for: indexPath) else { return }
            
            switch editingStyle {
                case .delete:
                    let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(parent.tag.id)\" from \"\(transaction.attributes.transactionDescription)\"?", preferredStyle: .actionSheet)
                    
                    let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { [self] _ in
                        Up.modifyTags(removing: parent.tag, from: transaction) { error in
                            DispatchQueue.main.async {
                                switch error {
                                    case .none:
                                        let nb = GrowingNotificationBanner(title: "Success", subtitle: "\(parent.tag.id) was removed from \(transaction.attributes.transactionDescription).", style: .success)
                                        
                                        nb.duration = 2
                                        
                                        nb.show()

                                        parent.fetchTransactions()
                                    default:
                                        let nb = GrowingNotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)
                                        
                                        nb.duration = 2
                                        
                                        nb.show()
                                }
                            }
                        }
                    }
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                    
                    cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                    
                    ac.addAction(confirmAction)
                    ac.addAction(cancelAction)
                    
                    parent.present(ac, animated: true)
                default:
                    break
            }
        }
    }
    
    // MARK: - Life Cycle
    
    init(tag: TagResource) {
        self.tag = tag
        super.init(nibName: nil, bundle: nil)
        log.debug("init(tag: \(tag.id))")
        dataSource.parent = self
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
        log.debug("viewWillAppear")
        fetchTransactions()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        log.debug("setEditing(editing: \(editing.description), animated: \(animated.description))")
        tableView.setEditing(editing, animated: animated)
    }
}

// MARK: - Configuration

private extension TransactionsByTagVC {
    private func configureProperties() {
        log.verbose("configureProperties")
        
        title = "Transactions by Tag"
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
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle())
        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
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

private extension TransactionsByTagVC {
    @objc private func appMovedToForeground() {
        log.verbose("appMovedToForeground")
        
        fetchTransactions()
    }
    
    @objc private func refreshTransactions() {
        log.verbose("refreshTransactions")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchTransactions()
        }
    }
    
    private func reloadSnapshot() {
        log.verbose("reloadSnapshot")
        
        var snap = dataSource.snapshot()

        snap.reloadItems(snap.itemIdentifiers)

        dataSource.apply(snap, animatingDifferences: false)
    }
    
    private func makeDataSource() -> DataSource {
        log.verbose("makeDataSource")
        
        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, transaction in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TransactionTableViewCell.reuseIdentifier, for: indexPath) as? TransactionTableViewCell else {
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
    
    private func fetchTransactions() {
        log.verbose("fetchTransactions")

        Up.listTransactions(filterBy: tag) { [self] result in
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
    
    private func display(_ transactions: [TransactionResource]) {
        log.verbose("display(transactions: \(transactions.count.description))")
        
        transactionsError = ""
        self.transactions = transactions
        
        if navigationItem.title != tag.id {
            navigationItem.title = tag.id
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

extension TransactionsByTagVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.debug("tableView(didSelectRowAt indexPath: \(indexPath))")
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let transaction = dataSource.itemIdentifier(for: indexPath) {
            navigationController?.pushViewController(TransactionDetailVC(transaction: transaction), animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove"
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let transaction = dataSource.itemIdentifier(for: indexPath) else { return nil }

        switch isEditing {
            case true:
                return nil
            case false:
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    UIMenu(children: [
                        UIAction(title: "Copy Description", image: R.image.textAlignright()) { _ in
                            UIPasteboard.general.string = transaction.attributes.transactionDescription
                        },
                        UIAction(title: "Copy Creation Date", image: R.image.calendarCircle()) { _ in
                            UIPasteboard.general.string = transaction.attributes.creationDate
                        },
                        UIAction(title: "Copy Amount", image: R.image.dollarsignCircle()) { _ in
                            UIPasteboard.general.string = transaction.attributes.amount.valueShort
                        },
                        UIAction(title: "Remove", image: R.image.trash(), attributes: .destructive) { [self] _ in
                            let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tag.id)\" from \"\(transaction.attributes.transactionDescription)\"?", preferredStyle: .actionSheet)

                            let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { _ in
                                Up.modifyTags(removing: tag, from: transaction) { error in
                                    DispatchQueue.main.async {
                                        switch error {
                                            case .none:
                                                let nb = GrowingNotificationBanner(title: "Success", subtitle: "\(tag.id) was removed from \(transaction.attributes.transactionDescription).", style: .success)

                                                nb.duration = 2

                                                nb.show()

                                                fetchTransactions()
                                            default:
                                                let nb = GrowingNotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                                                nb.duration = 2

                                                nb.show()
                                        }
                                    }
                                }
                            }

                            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

                            cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

                            ac.addAction(confirmAction)
                            ac.addAction(cancelAction)

                            present(ac, animated: true)
                        }
                    ])
                }
        }
    }
}

// MARK: - UISearchBarDelegate

extension TransactionsByTagVC: UISearchBarDelegate {
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
