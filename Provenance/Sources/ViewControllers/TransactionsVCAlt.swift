import IGListKit
import Alamofire
import UIKit

final class TransactionsVCAlt: ViewController {
  // MARK: - Properties

  private lazy var filterBarButtonItem = UIBarButtonItem(image: .sliderHorizontal3, menu: filterMenu)

  private lazy var searchController = UISearchController(self)

  private lazy var adapter: ListAdapter = {
    return ListAdapter(updater: ListAdapterUpdater(), viewController: self)
  }()

  private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .sectionHeadersPinned)

  private let spinToken = "spinner"

  private var apiKeyObserver: NSKeyValueObservation?

  private var dateStyleObserver: NSKeyValueObservation?

  private var settledOnlyObserver: NSKeyValueObservation?

  private var paginationCursorObserver: NSKeyValueObservation?

  private var transactionGroupingObserver: NSKeyValueObservation?

  private var cursor: String?

  private var noTransactions: Bool = false

  private var transactionsError = String()

  private lazy var transactionGrouping: TransactionGroupingEnum = App.userDefaults.appTransactionGrouping {
    didSet {
      if App.userDefaults.transactionGrouping != transactionGrouping.rawValue {
        App.userDefaults.transactionGrouping = transactionGrouping.rawValue
      }
      filterUpdates()
    }
  }

  private var transactions = [TransactionResource]() {
    didSet {
      transactionsUpdates()
    }
  }

  private var filteredTransactions: [TransactionResource] {
    return preFilteredTransactions.filtered(searchBar: searchController.searchBar)
  }

  private var preFilteredTransactions: [TransactionResource] {
    return transactions.filter { (transaction) in
      return (!showSettledOnly || transaction.attributes.status.isSettled) && (categoryFilter == .all || categoryFilter.rawValue == transaction.relationships.category.data?.id)
    }
  }

  private lazy var categoryFilter: TransactionCategory = App.userDefaults.appSelectedCategory {
    didSet {
      if App.userDefaults.selectedCategory != categoryFilter.rawValue {
        App.userDefaults.selectedCategory = categoryFilter.rawValue
      }
      filterUpdates()
    }
  }

  private lazy var showSettledOnly: Bool = App.userDefaults.settledOnly {
    didSet {
      if App.userDefaults.settledOnly != showSettledOnly {
        App.userDefaults.settledOnly = showSettledOnly
      }
      filterUpdates()
    }
  }

  private var loading: Bool = false

  // MARK: - Life Cycle

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    adapter.collectionView = collectionView
    adapter.dataSource = self
    adapter.scrollViewDelegate = self
  }

  deinit {
    removeObservers()
    print("deinit")
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(collectionView)
    configureObservers()
    configureCollectionView()
    configureSelf()
    configureNavigation()
    fetchingTasks()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    collectionView.frame = view.bounds
  }
}

// MARK: - Configuration

extension TransactionsVCAlt {
  private func configureCollectionView() {
    collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    collectionView.refreshControl = UIRefreshControl(self, action: #selector(refreshTransactions))
  }

  private func configureSelf() {
    title = "Transactions"
    definesPresentationContext = true
  }

  private func configureObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: .willEnterForegroundNotification, object: nil)
    apiKeyObserver = App.userDefaults.observe(\.apiKey, options: .new) { [weak self] (_, _) in
      self?.fetchingTasks()
    }
    dateStyleObserver = App.userDefaults.observe(\.dateStyle, options: .new) { [weak self] (_, _) in
      self?.adapter.performUpdates(animated: true)
    }
    settledOnlyObserver = App.userDefaults.observe(\.settledOnly, options: .new) { [weak self] (_, change) in
      guard let value = change.newValue else { return }
      self?.showSettledOnly = value
    }
    paginationCursorObserver = App.userDefaults.observe(\.paginationCursor, options: .new) { [weak self] (_, change) in
      guard let value = change.newValue else { return }
      self?.cursor = value.isEmpty ? nil : value
    }
    transactionGroupingObserver = App.userDefaults.observe(\.transactionGrouping, options: .new) { [weak self] (_, change) in
      guard let value = change.newValue, let grouping = TransactionGroupingEnum(rawValue: value) else { return }
      self?.transactionGrouping = grouping
    }
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForegroundNotification, object: nil)
    apiKeyObserver?.invalidate()
    apiKeyObserver = nil
    dateStyleObserver?.invalidate()
    dateStyleObserver = nil
    settledOnlyObserver?.invalidate()
    settledOnlyObserver = nil
    paginationCursorObserver?.invalidate()
    paginationCursorObserver = nil
    transactionGroupingObserver?.invalidate()
    transactionGroupingObserver = nil
  }

  private func configureNavigation() {
    navigationItem.title = "Loading"
    navigationItem.largeTitleDisplayMode = .always
    navigationItem.backBarButtonItem = .dollarsignCircle
    navigationItem.searchController = searchController
  }
}

// MARK: - Actions

extension TransactionsVCAlt {
  @objc
  private func appMovedToForeground() {
    fetchingTasks()
  }

  @objc
  private func switchDateStyle() {
    switch App.userDefaults.appDateStyle {
    case .absolute:
      App.userDefaults.appDateStyle = .relative
    case .relative:
      App.userDefaults.appDateStyle = .absolute
    }
  }

  @objc
  private func refreshTransactions() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.fetchingTasks()
    }
  }

  private func transactionsUpdates() {
    loading = false
    noTransactions = transactions.isEmpty
    adapter.performUpdates(animated: true)
    collectionView.refreshControl?.endRefreshing()
    searchController.searchBar.placeholder = preFilteredTransactions.searchBarPlaceholder
  }

  private func filterUpdates() {
    filterBarButtonItem.menu = filterMenu
    searchController.searchBar.placeholder = preFilteredTransactions.searchBarPlaceholder
    adapter.performUpdates(animated: true)
  }

  private func fetchingTasks() {
    fetchTransactions()
  }

  private var filterMenu: UIMenu {
    return .transactionsFilterMenu(
      categoryFilter: categoryFilter,
      groupingFilter: transactionGrouping,
      showSettledOnly: showSettledOnly,
      completion: { (type) in
        switch type {
        case let .category(category):
          self.categoryFilter = category
        case let .grouping(grouping):
          self.transactionGrouping = grouping
        case let .settledOnly(settledOnly):
          self.showSettledOnly = settledOnly
        }
      }
    )
  }

  private func fetchTransactions() {
    Up.listTransactions { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(transactions):
          self.display(transactions)
        case let .failure(error):
          self.display(error)
        }
      }
    }
  }

  private func fetchTransactionsWithCursor() {
    Up.listTransactions(cursor: cursor) { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(transactions):
          self.transactions.append(contentsOf: transactions)
        case let .failure(error):
          self.display(error)
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
    if navigationItem.leftBarButtonItem == nil {
      navigationItem.setLeftBarButton(.dateStyleButtonItem(self, action: #selector(switchDateStyle)), animated: true)
    }
    if navigationItem.rightBarButtonItem == nil {
      navigationItem.setRightBarButton(filterBarButtonItem, animated: true)
    }
  }

  private func display(_ error: AFError) {
    transactionsError = error.errorDescription ?? error.localizedDescription
    transactions.removeAll()
    if navigationItem.title != "Error" {
      navigationItem.title = "Error"
    }
    if navigationItem.leftBarButtonItem != nil {
      navigationItem.setLeftBarButton(nil, animated: true)
    }
    if navigationItem.rightBarButtonItem != nil {
      navigationItem.setRightBarButton(nil, animated: true)
    }
  }
}

// MARK: - ListAdapterDataSource

extension TransactionsVCAlt: ListAdapterDataSource {
  func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
    var objects = filteredTransactions.sortedTransactionModelsAlt as [ListDiffable]
    if loading {
      objects.append(spinToken as ListDiffable)
    }
    return objects
  }

  func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
    switch object {
    case is String:
      return .spinnerSectionController()
    case is SortedTransactionModelAlt:
      return TransactionBindingSC()
    default:
      fatalError()
    }
  }

  func emptyView(for listAdapter: ListAdapter) -> UIView? {
    if filteredTransactions.isEmpty && transactionsError.isEmpty {
      if transactions.isEmpty && !noTransactions {
        return .loadingView(frame: collectionView.bounds, contentType: .transactions)
      } else {
        return .noContentView(frame: collectionView.bounds, type: .transactions)
      }
    } else {
      if !transactionsError.isEmpty {
        return .errorView(frame: collectionView.bounds, text: transactionsError)
      } else {
        return nil
      }
    }
  }
}

// MARK: - UIScrollViewDelegate

extension TransactionsVCAlt: UIScrollViewDelegate {
  func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                 withVelocity velocity: CGPoint,
                                 targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
    if cursor != nil && !loading && distance < 200 && !searchController.isActive && !searchController.searchBar.searchTextField.hasText {
      loading = true
      adapter.performUpdates(animated: true)
      DispatchQueue.global(qos: .default).async {
        sleep(2)
        self.fetchTransactionsWithCursor()
      }
    }
  }
}

// MARK: - UISearchBarDelegate

extension TransactionsVCAlt: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    adapter.performUpdates(animated: true)
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if searchBar.searchTextField.hasText {
      searchBar.clear()
      adapter.performUpdates(animated: true)
    }
  }
}
