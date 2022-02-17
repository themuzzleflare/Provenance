import UIKit
import MarqueeLabel

final class AccountDetailVC: ViewController {
  // MARK: - Properties

  private var account: AccountResource {
    didSet {
      print("didSet account")
      supplementaryState.append("1")
    }
  }

  private var transaction: TransactionResource? {
    didSet {
      print("didSet transaction")
      supplementaryState.append("1")
    }
  }

  private var supplementaryState: [String] = [] {
    didSet {
      if supplementaryState.count == 2 {
        print("supplementaryState complete")
        supplementaryState.removeAll()
        self.tableView.refreshControl?.endRefreshing()
        self.applySnapshot()
      }
    }
  }

  private typealias DataSource = UITableViewDiffableDataSource<DetailSection, DetailItem>

  private typealias Snapshot = NSDiffableDataSourceSnapshot<DetailSection, DetailItem>

  private lazy var dataSource = DataSource(
    tableView: tableView,
    cellProvider: { (tableView, indexPath, attribute) in
      guard let cell = tableView.dequeueReusableCell(withIdentifier: AttributeCell.reuseIdentifier, for: indexPath) as? AttributeCell else {
        fatalError("Unable to dequeue reusable cell with identifier: \(AttributeCell.reuseIdentifier)")
      }
      cell.text = attribute.id
      cell.detailFont = attribute.valueFont
      cell.detailText = attribute.value
      return cell
    }
  )

  private var dateStyleObserver: NSKeyValueObservation?

  private let tableView = UITableView(frame: .zero, style: .grouped)

  private var sections: [DetailSection] {
    return .accountDetail(account: account, transaction: transaction).filtered
  }

  // MARK: - Life Cycle

  init(account: AccountResource, transaction: TransactionResource? = nil) {
    self.account = account
    self.transaction = transaction
    super.init(nibName: nil, bundle: nil)
  }

  deinit {
    removeObservers()
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(tableView)
    configureObservers()
    configureSelf()
    configureNavigation()
    configureTableView()
    applySnapshot(animate: false)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tableView.frame = view.bounds
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchingTasks()
  }
}

// MARK: - Configuration

extension AccountDetailVC {
  private func configureSelf() {
    title = "Account Details"
  }

  private func configureObservers() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(appMovedToForeground),
                                           name: .willEnterForeground,
                                           object: nil)
    dateStyleObserver = Store.provenance.observe(\.dateStyle, options: .new) { [weak self] (_, _) in
      DispatchQueue.main.async {
        self?.applySnapshot()
      }
    }
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForeground, object: nil)
    dateStyleObserver?.invalidate()
    dateStyleObserver = nil
  }

  private func configureNavigation() {
    navigationItem.title = account.attributes.displayName
    navigationItem.titleView = MarqueeLabel(text: account.attributes.displayName)
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.leftBarButtonItem = .close(self, action: #selector(closeWorkflow))
  }

  private func configureTableView() {
    tableView.dataSource = dataSource
    tableView.delegate = self
    tableView.register(AttributeCell.self, forCellReuseIdentifier: AttributeCell.reuseIdentifier)
    tableView.refreshControl = UIRefreshControl(self, action: #selector(refreshData))
    tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    tableView.showsVerticalScrollIndicator = false
    tableView.backgroundColor = .systemBackground
  }
}

// MARK: - Actions

extension AccountDetailVC {
  @objc
  private func appMovedToForeground() {
    DispatchQueue.main.async {
      self.fetchingTasks()
    }
  }

  @objc
  private func refreshData() {
    fetchingTasks()
  }

  @objc
  private func closeWorkflow() {
    navigationController?.dismiss(animated: true)
  }

  private func fetchingTasks() {
    fetchAccount()
    fetchTransaction()
  }

  private func applySnapshot(animate: Bool = true) {
    var snapshot = Snapshot()
    snapshot.appendSections(self.sections)
    self.sections.forEach { snapshot.appendItems($0.items, toSection: $0) }
    self.dataSource.apply(snapshot, animatingDifferences: animate)
  }

  private func fetchAccount() {
    Up.retrieveAccount(for: account) { (result) in
      switch result {
      case let .success(account):
        self.account = account
      case .failure:
        break
      }
    }
  }

  private func fetchTransaction() {
    Up.retrieveLatestTransaction(for: account) { (result) in
      switch result {
      case let .success(transaction):
        self.transaction = transaction
      case .failure:
        self.transaction = nil
      }
    }
  }
}

// MARK: - UITableViewDelegate

extension AccountDetailVC: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }
}
