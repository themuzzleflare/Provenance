import UIKit
import FLAnimatedImage
import NotificationBannerSwift
import TinyConstraints
import Rswift

final class TransactionsByTagVC: UIViewController {
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
            true
        }

        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            guard let transaction = itemIdentifier(for: indexPath) else {
                return
            }

            switch editingStyle {
                case .delete:
                    let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(parent.tag.id)\" from \"\(transaction.attributes.description)\"?", preferredStyle: .actionSheet)

                    let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { [self] _ in
                        upApi.modifyTags(removing: parent.tag, from: transaction) { error in
                            switch error {
                                case .none:
                                    DispatchQueue.main.async {
                                        let notificationBanner = NotificationBanner(title: "Success", subtitle: "\(parent.tag.id) was removed from \(transaction.attributes.description).", style: .success)

                                        notificationBanner.duration = 2

                                        notificationBanner.show()
                                        parent.fetchTransactions()
                                    }
                                default:
                                    DispatchQueue.main.async {
                                        let notificationBanner = NotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                                        notificationBanner.duration = 2

                                        notificationBanner.show()
                                    }
                            }
                        }
                    }

                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

                    cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")

                    ac.addAction(confirmAction)
                    ac.addAction(cancelAction)

                    parent.present(ac, animated: true)
                default:
                    break
            }
        }
    }

    private let transactionsPagination = Pagination(prev: nil, next: nil)
    private let tableRefreshControl = RefreshControl(frame: .zero)
    private let searchController = SearchController(searchResultsController: nil)
    private let tableView = UITableView(frame: .zero, style: .grouped)

    private var dateStyleObserver: NSKeyValueObservation?
    private var noTransactions: Bool = false
    private var transactions: [TransactionResource] = [] {
        didSet {
            noTransactions = transactions.isEmpty

            if transactions.isEmpty {
                navigationController?.popViewController(animated: true)
            } else {
                applySnapshot(animate: isEditing)
                tableView.refreshControl?.endRefreshing()
                searchController.searchBar.placeholder = "Search \(transactions.count.description) \(transactions.count == 1 ? "Transaction" : "Transactions")"
            }
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

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        dataSource.parent = self
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

        fetchTransactions()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        tableView.setEditing(editing, animated: animated)
    }
}

// MARK: - Configuration

private extension TransactionsByTagVC {
    private func configureProperties() {
        title = "Transactions by Tag"
        definesPresentationContext = true

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { [self] object, change in
            applySnapshot()
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle())
        navigationItem.rightBarButtonItem = editButtonItem
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

private extension TransactionsByTagVC {
    @objc private func appMovedToForeground() {
        fetchTransactions()
    }

    @objc private func refreshTransactions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchTransactions()
        }
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

                    loadingIndicator.center(in: view)
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
        if #available(iOS 15.0, *) {
            async {
                do {
                    let transactions = try await Up.listTransactions(filterBy: tag)
                    display(transactions)
                } catch {
                    display(error as! NetworkError)
                }
            }
        } else {
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
    }

    private func display(_ transactions: [TransactionResource]) {
        transactionsError = ""
        self.transactions = transactions

        if navigationItem.title != tag.id {
            navigationItem.title = tag.id
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

extension TransactionsByTagVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let transaction = dataSource.itemIdentifier(for: indexPath) {
            let vc = TransactionDetailCVC(transaction: transaction)

            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        "Remove"
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
                },
                UIAction(title: "Remove", image: R.image.trash(), attributes: .destructive) { [self] _ in
                    let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tag.id)\" from \"\(transaction.attributes.description)\"?", preferredStyle: .actionSheet)

                    let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { _ in
                        upApi.modifyTags(removing: tag, from: transaction) { error in
                            switch error {
                                case .none:
                                    DispatchQueue.main.async {
                                        let notificationBanner = NotificationBanner(title: "Success", subtitle: "\(tag.id) was removed from \(transaction.attributes.description).", style: .success)

                                        notificationBanner.duration = 2

                                        notificationBanner.show()
                                        fetchTransactions()
                                    }
                                default:
                                    DispatchQueue.main.async {
                                        let notificationBanner = NotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                                        notificationBanner.duration = 2

                                        notificationBanner.show()
                                    }
                            }
                        }
                    }

                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                    
                    cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
                    
                    ac.addAction(confirmAction)
                    ac.addAction(cancelAction)

                    present(ac, animated: true)
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
