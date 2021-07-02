import UIKit
import WidgetKit
import IGListKit
import FLAnimatedImage
import TinyConstraints
import Rswift

final class TransactionsCVC: UIViewController {
    // MARK: - Properties

    private lazy var filterButton = UIBarButtonItem(image: R.image.sliderHorizontal3(), menu: filterMenu())
    private lazy var adapter = ListAdapter(updater: ListAdapterUpdater(), viewController: self)

    private let collectionRefreshControl = RefreshControl(frame: .zero)
    private let searchController = SearchController(searchResultsController: nil)
    private let transactionsPagination = Pagination(prev: nil, next: nil)
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionHeadersPinToVisibleBounds = true
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    private var apiKeyObserver: NSKeyValueObservation?
    private var dateStyleObserver: NSKeyValueObservation?
    private var searchBarPlaceholder: String {
        "Search \(preFilteredTransactions.count.description) \(preFilteredTransactions.count == 1 ? "Transaction" : "Transactions")"
    }
    private var noTransactions: Bool = false
    private var transactionsError: String = ""
    private var transactions: [TransactionResource] = [] {
        didSet {
            transactionsUpdates()
        }
    }
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
    private var filter: CategoryFilter = .all {
        didSet {
            filterUpdates()
        }
    }
    private var showSettledOnly: Bool = false {
        didSet {
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

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)

        configureAdapter()
        configureCollectionView()
        configureProperties()
        configureNavigation()
        configureSearch()
        configureRefreshControl()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchingTasks()
    }
}

// MARK: - Configuration

private extension TransactionsCVC {
    private func configureAdapter() {
        adapter.collectionView = collectionView
        adapter.dataSource = self
        adapter.collectionViewDelegate = self
    }

    private func configureCollectionView() {
        collectionView.refreshControl = collectionRefreshControl
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .systemGroupedBackground
    }

    private func configureProperties() {
        title = "Transactions"
        definesPresentationContext = true

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { [self] object, change in
            fetchingTasks()
        }
        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { [self] object, change in
            adapter.reloadData()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle())
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func configureSearch() {
        searchController.searchBar.delegate = self
    }

    private func configureRefreshControl() {
        collectionRefreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
    }
}

// MARK: - Actions

private extension TransactionsCVC {
    @objc private func appMovedToForeground() {
        fetchingTasks()
    }

    @objc private func switchDateStyle() {
        if appDefaults.dateStyle == "Absolute" {
            appDefaults.dateStyle = "Relative"
        } else if appDefaults.dateStyle == "Relative" {
            appDefaults.dateStyle = "Absolute"
        }
    }

    @objc private func refreshTransactions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchingTasks()
        }
    }

    private func transactionsUpdates() {
        noTransactions = transactions.isEmpty
        adapter.performUpdates(animated: false)
        collectionView.refreshControl?.endRefreshing()
        searchController.searchBar.placeholder = searchBarPlaceholder
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func filterUpdates() {
        filterButton.menu = filterMenu()
        searchController.searchBar.placeholder = searchBarPlaceholder
        adapter.performUpdates(animated: false)
    }

    private func fetchingTasks() {
        fetchTransactions()
    }

    private func filterMenu() -> UIMenu {
        UIMenu(options: .displayInline, children: [
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

        if navigationItem.title != "Transactions" {
            navigationItem.title = "Transactions"
        }
        if navigationItem.leftBarButtonItems == nil {
            navigationItem.setLeftBarButtonItems([UIBarButtonItem(image: R.image.calendarBadgeClock(), style: .plain, target: self, action: #selector(switchDateStyle)), filterButton], animated: true)
        }
    }

    private func display(_ error: NetworkError) {
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

// MARK: - ListAdapterDataSource

extension TransactionsCVC: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        sortedTransactions.map { transaction in
            SortedTransactions(day: transaction.key, transactions: transaction.value)
        }
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        TransactionsSC()
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        if filteredTransactions.isEmpty && transactionsError.isEmpty {
            if transactions.isEmpty && !noTransactions {
                let view = UIView(frame: collectionView.bounds)

                let loadingIndicator = FLAnimatedImageView()

                view.addSubview(loadingIndicator)

                loadingIndicator.centerInSuperview()
                loadingIndicator.width(100)
                loadingIndicator.height(100)
                loadingIndicator.animatedImage = upZapSpinTransparentBackground

                return view
            } else {
                let view = UIView(frame: collectionView.bounds)

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
            }
        } else {
            if !transactionsError.isEmpty {
                let view = UIView(frame: collectionView.bounds)

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
            } else {
                return nil
            }
        }
    }
}

// MARK: - UICollectionViewDelegate

extension TransactionsCVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let transaction = sortedTransactions[indexPath.section].value[indexPath.item]

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

extension TransactionsCVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        adapter.performUpdates(animated: false)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if !searchBar.text!.isEmpty {
            searchBar.text = ""
            adapter.performUpdates(animated: false)
        }
    }
}
