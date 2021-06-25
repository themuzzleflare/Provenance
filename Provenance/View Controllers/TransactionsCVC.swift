import UIKit
import WidgetKit
import IGListKit
import FLAnimatedImage
import TinyConstraints
import Rswift

final class TransactionsCVC: ViewController {
    // MARK: - Properties

    private lazy var filterButton = UIBarButtonItem(image: R.image.sliderHorizontal3(), menu: filterMenu())
    private lazy var adapter = ListAdapter(updater: ListAdapterUpdater(), viewController: self)

    private let collectionRefreshControl = RefreshControl(frame: .zero)
    private let searchController = SearchController(searchResultsController: nil)
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    private var apiKeyObserver: NSKeyValueObservation?
    private var dateStyleObserver: NSKeyValueObservation?
    private var searchBarPlaceholder: String {
        "Search \(preFilteredTransactions.count.description) \(preFilteredTransactions.count == 1 ? "Transaction" : "Transactions")"
    }
    private var noTransactions: Bool = false
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
    private var transactionsPagination: Pagination = Pagination(prev: nil, next: nil)
    private var transactionsError: String = ""
    private var transactions: [TransactionResource] = [] {
        didSet {
            noTransactions = transactions.isEmpty
            adapter.performUpdates(animated: true)
            adapter.collectionView?.refreshControl?.endRefreshing()
            WidgetCenter.shared.reloadAllTimelines()
            searchController.searchBar.placeholder = searchBarPlaceholder
        }
    }
    private var accounts: [AccountResource] = []
    private var categories: [CategoryResource] = []
    private var filter: CategoryFilter = .all {
        didSet {
            filterButton.menu = filterMenu()
            searchController.searchBar.placeholder = searchBarPlaceholder
            adapter.performUpdates(animated: true)
        }
    }
    private var showSettledOnly: Bool = false {
        didSet {
            filterButton.menu = filterMenu()
            searchController.searchBar.placeholder = searchBarPlaceholder
            adapter.performUpdates(animated: true)
        }
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchTransactions()
        fetchAccounts()
        fetchCategories()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
}

// MARK: - Configuration

private extension TransactionsCVC {
    private func configureAdapter() {
        adapter.collectionView = collectionView
        adapter.dataSource = self
        adapter.collectionViewDelegate = self
        adapter.collectionView?.refreshControl = collectionRefreshControl
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.showsHorizontalScrollIndicator = false
    }

    private func configureProperties() {
        title = "Transactions"
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { object, change in
            self.fetchTransactions()
            self.fetchAccounts()
            self.fetchCategories()
        }
        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { object, change in
            self.adapter.reloadData()
            WidgetCenter.shared.reloadAllTimelines()
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
        collectionRefreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
    }
}

// MARK: - Actions

private extension TransactionsCVC {
    @objc private func appMovedToForeground() {
        fetchTransactions()
        fetchAccounts()
        fetchCategories()
    }

    @objc private func switchDateStyle() {
        if appDefaults.dateStyle == "Absolute" {
            appDefaults.dateStyle = "Relative"
        } else if appDefaults.dateStyle == "Relative" {
            appDefaults.dateStyle = "Absolute"
        }
    }

    @objc private func refreshTransactions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchTransactions()
            self.fetchAccounts()
            self.fetchCategories()
        }
    }

    private func filterMenu() -> UIMenu {
        UIMenu(options: .displayInline, children: [
            UIMenu(title: "Category", image: filter == .all ? R.image.trayFull() : R.image.trayFullFill(), children: CategoryFilter.allCases.map { category in
            UIAction(title: categoryName(for: category), state: filter == category ? .on : .off) { action in
                self.filter = category
            }
        }),
            UIAction(title: "Settled Only", image: showSettledOnly ? R.image.checkmarkCircleFill() : R.image.checkmarkCircle(), state: showSettledOnly ? .on : .off) { action in
            self.showSettledOnly.toggle()
        }
        ])
    }

    private func fetchTransactions() {
        upApi.listTransactions { result in
            switch result {
                case .success(let transactions):
                    DispatchQueue.main.async {
                        self.transactionsError = ""
                        self.transactions = transactions
                        if self.navigationItem.title != "Transactions" {
                            self.navigationItem.title = "Transactions"
                        }
                        if self.navigationItem.leftBarButtonItems == nil {
                            self.navigationItem.setLeftBarButtonItems([UIBarButtonItem(image: R.image.calendarBadgeClock(), style: .plain, target: self, action: #selector(self.switchDateStyle)), self.filterButton], animated: true)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.transactionsError = errorString(for: error)
                        self.transactions = []
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        if self.navigationItem.leftBarButtonItems != nil {
                            self.navigationItem.setLeftBarButtonItems(nil, animated: true)
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

// MARK: - ListAdapterDataSource

extension TransactionsCVC: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        filteredTransactions
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        let controller = TransactionsSectionController()
        controller.accounts = accounts
        controller.categories = categories
        return controller
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        if filteredTransactions.isEmpty && transactionsError.isEmpty {
            if transactions.isEmpty && !noTransactions {
                let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))
                let loadingIndicator = FLAnimatedImageView()
                loadingIndicator.animatedImage = upZapSpinTransparentBackground
                loadingIndicator.width(100)
                loadingIndicator.height(100)
                view.addSubview(loadingIndicator)
                loadingIndicator.center(in: view)
                return view
            } else {
                let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))
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
            }
        } else {
            if !transactionsError.isEmpty {
                let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))
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
            } else {
                return nil
            }
        }
    }
}

// MARK: - UICollectionViewDelegate

extension TransactionsCVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let transaction = filteredTransactions[indexPath.item]
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

extension TransactionsCVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        adapter.performUpdates(animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if !searchBar.text!.isEmpty {
            searchBar.text = ""
            adapter.performUpdates(animated: true)
        }
    }
}
