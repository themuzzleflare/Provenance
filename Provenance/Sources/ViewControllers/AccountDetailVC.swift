import UIKit
import MarqueeLabel

final class AccountDetailVC: ViewController {
    // MARK: - Properties
  
  private var account: AccountResource {
    didSet {
      applySnapshot()
      tableView.refreshControl?.endRefreshing()
    }
  }
  
  private var transaction: TransactionResource? {
    didSet {
      applySnapshot()
      tableView.refreshControl?.endRefreshing()
    }
  }
  
  private typealias DataSource = UITableViewDiffableDataSource<DetailSection, DetailItem>
  
  private typealias Snapshot = NSDiffableDataSourceSnapshot<DetailSection, DetailItem>
  
  private lazy var dataSource = makeDataSource()
  
  private let tableView = UITableView(frame: .zero, style: .grouped)
  
  private var sections: [DetailSection] {
    return .accountDetailSections(account: account, transaction: transaction).filtered
  }
  
    // MARK: - Life Cycle
  
  init(account: AccountResource, transaction: TransactionResource? = nil) {
    self.account = account
    self.transaction = transaction
    super.init(nibName: nil, bundle: nil)
  }
  
  deinit {
    removeObserver()
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureObserver()
    view.addSubview(tableView)
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

private extension AccountDetailVC {
  private func configureSelf() {
    title = "Account Details"
  }
  
  private func configureObserver() {
    NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: .willEnterForegroundNotification, object: nil)
  }
  
  private func removeObserver() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForegroundNotification, object: nil)
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

private extension AccountDetailVC {
  @objc private func appMovedToForeground() {
    fetchingTasks()
  }
  
  @objc private func refreshData() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
      fetchingTasks()
    }
  }
  
  @objc private func closeWorkflow() {
    navigationController?.dismiss(animated: true)
  }
  
  private func fetchingTasks() {
    fetchAccount()
    fetchTransaction()
  }
  
  private func makeDataSource() -> DataSource {
    return DataSource(
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
  }
  
  private func applySnapshot(animate: Bool = true) {
    var snapshot = Snapshot()
    snapshot.appendSections(sections)
    sections.forEach { snapshot.appendItems($0.items, toSection: $0) }
    dataSource.apply(snapshot, animatingDifferences: animate)
  }
  
  private func fetchAccount() {
    UpFacade.retrieveAccount(for: account) { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(account):
          self.account = account
        case .failure:
          break
        }
      }
    }
  }
  
  private func fetchTransaction() {
    UpFacade.retrieveLatestTransaction(for: account) { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(transaction):
          self.transaction = transaction
        case .failure:
          break
        }
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
