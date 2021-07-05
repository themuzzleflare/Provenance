import UIKit
import FLAnimatedImage
import TinyConstraints
import Rswift

final class AddTagWorkflowVC: UIViewController {
    // MARK: - Properties

    private enum Section {
        case main
    }

    private typealias DataSource = UITableViewDiffableDataSource<Section, TransactionResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, TransactionResource>

    private lazy var dataSource = makeDataSource()

    private let transactionsPagination = Pagination(prev: nil, next: nil)
    private let tableRefreshControl = RefreshControl(frame: .zero)
    private let searchController = SearchController(searchResultsController: nil)
    private let tableView = UITableView(frame: .zero, style: .grouped)

    private var dateStyleObserver: NSKeyValueObservation?
    private var noTransactions: Bool = false
    private var transactions: [TransactionResource] = [] {
        didSet {
            noTransactions = transactions.isEmpty
            applySnapshot()
            tableView.refreshControl?.endRefreshing()
            searchController.searchBar.placeholder = "Search \(transactions.count.description) \(transactions.count == 1 ? "Transaction" : "Transactions")"
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
}

// MARK: - Configuration

private extension AddTagWorkflowVC {
    private func configureProperties() {
        title = "Transaction Selection"
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
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

private extension AddTagWorkflowVC {
    @objc private func appMovedToForeground() {
        fetchTransactions()
    }

    @objc private func refreshTransactions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchTransactions()
        }
    }

    @objc private func closeWorkflow() {
        navigationController?.dismiss(animated: true)
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

    private func fetchTransactions() {
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
        transactionsError = ""
        self.transactions = transactions

        if navigationItem.title != "Select Transaction" {
            navigationItem.title = "Select Transaction"
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

extension AddTagWorkflowVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let transaction = dataSource.itemIdentifier(for: indexPath) {
            navigationController?.pushViewController(AddTagWorkflowTwoVC(transaction: transaction), animated: true)
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

extension AddTagWorkflowVC: UISearchBarDelegate {
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
