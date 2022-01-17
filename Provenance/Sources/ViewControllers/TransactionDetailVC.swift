import UIKit
import MarqueeLabel
import Alamofire

final class TransactionDetailVC: ViewController {
  // MARK: - Properties

  private var transaction: TransactionResource {
    didSet {
      fetchingTasks()
    }
  }

  private class DataSource: UITableViewDiffableDataSource<DetailSection, DetailItem> {
    private var transaction: TransactionResource

    init(transaction: TransactionResource,
         tableView: UITableView,
         cellProvider: @escaping UITableViewDiffableDataSource<DetailSection, DetailItem>.CellProvider) {
      self.transaction = transaction
      super.init(tableView: tableView, cellProvider: cellProvider)
    }

    deinit {
      print("\(#function) \(String(describing: type(of: self)))")
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
      guard section == 0 else { return nil }
      return transaction.id
    }
  }

  private var dateStyleObserver: NSKeyValueObservation?

  private typealias Snapshot = NSDiffableDataSourceSnapshot<DetailSection, DetailItem>

  private lazy var dataSource = makeDataSource()

  private let tableView = UITableView(frame: .zero, style: .grouped)

  private var filteredSections: [DetailSection] {
    return .transactionDetailSections(
      transaction: transaction,
      account: account,
      transferAccount: transferAccount,
      parentCategory: parentCategory,
      category: category
    ).filtered
  }

  private var account: AccountResource? {
    didSet {
      applySnapshot()
    }
  }

  private var transferAccount: AccountResource? {
    didSet {
      applySnapshot()
    }
  }

  private var parentCategory: CategoryResource? {
    didSet {
      applySnapshot()
    }
  }

  private var category: CategoryResource? {
    didSet {
      applySnapshot()
    }
  }

  // MARK: - Life Cycle

  init(transaction: TransactionResource) {
    self.transaction = transaction
    super.init(nibName: nil, bundle: nil)
  }

  deinit {
    removeObserver()
    print("\(#function) \(String(describing: type(of: self)))")
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(tableView)
    configureObserver()
    configureSelf()
    configureTableView()
    configureNavigation()
    applySnapshot()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tableView.frame = view.bounds
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchTransaction()
  }
}

// MARK: - Configuration

extension TransactionDetailVC {
  private func configureSelf() {
    title = "Transaction Details"
  }

  private func configureObserver() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(appMovedToForeground),
                                           name: .willEnterForegroundNotification,
                                           object: nil)
    dateStyleObserver = UserDefaults.provenance.observe(\.dateStyle, options: .new) { [weak self] (_, _) in
      self?.applySnapshot()
    }
  }

  private func removeObserver() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForegroundNotification, object: nil)
    dateStyleObserver?.invalidate()
    dateStyleObserver = nil
  }

  private func configureTableView() {
    tableView.dataSource = dataSource
    tableView.delegate = self
    tableView.register(AttributeCell.self, forCellReuseIdentifier: AttributeCell.reuseIdentifier)
    tableView.refreshControl = UIRefreshControl(self, action: #selector(refreshTransaction))
    tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    tableView.showsVerticalScrollIndicator = false
    tableView.backgroundColor = .systemBackground
  }

  private func configureNavigation() {
    navigationItem.title = transaction.attributes.description
    navigationItem.titleView = MarqueeLabel(text: transaction.attributes.description)
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.setRightBarButton(.transactionStatusIcon(self, status: transaction.attributes.status, action: #selector(openStatusIconHelpView)), animated: false)
  }
}

// MARK: - Actions

extension TransactionDetailVC {
  @objc
  private func appMovedToForeground() {
    fetchTransaction()
  }

  @objc
  private func openStatusIconHelpView() {
    let viewController = NavigationController(rootViewController: StatusIconHelpView())
    present(viewController, animated: true)
  }

  @objc
  private func refreshTransaction() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.fetchTransaction()
    }
  }

  func editCategory() {
    let viewController = NavigationController(rootViewController: AddCategoryCategorySelectionVC(transaction: transaction, fromTransactionDetail: true))
    present(.fullscreen(viewController), animated: true)
  }

  private func fetchingTasks() {
    Up.retrieveAccount(for: transaction.relationships.account.data.id) { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(account):
          self.account = account
        case .failure:
          break
        }
      }
    }

    if let transferAccount = transaction.relationships.transferAccount.data {
      Up.retrieveAccount(for: transferAccount.id) { (result) in
        DispatchQueue.main.async {
          switch result {
          case let .success(account):
            self.transferAccount = account
          case .failure:
            break
          }
        }
      }
    }

    if let parentCategory = transaction.relationships.parentCategory.data {
      Up.retrieveCategory(for: parentCategory.id) { (result) in
        DispatchQueue.main.async {
          switch result {
          case let .success(category):
            self.parentCategory = category
          case .failure:
            break
          }
        }
      }
    } else {
      self.parentCategory = nil
    }

    if let category = transaction.relationships.category.data {
      Up.retrieveCategory(for: category.id) { (result) in
        DispatchQueue.main.async {
          switch result {
          case let .success(category):
            self.category = category
          case .failure:
            break
          }
        }
      }
    } else {
      self.category = nil
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.tableView.refreshControl?.endRefreshing()
      self.configureNavigation()
    }
  }

  private func makeDataSource() -> DataSource {
    return DataSource(
      transaction: transaction,
      tableView: tableView,
      cellProvider: { (tableView, indexPath, attribute) in
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AttributeCell.reuseIdentifier, for: indexPath) as? AttributeCell else {
          fatalError("Unable to dequeue reusable cell with identifier: \(AttributeCell.reuseIdentifier)")
        }
        cell.selectionStyle = attribute.cellSelectionStyle
        cell.accessoryType = attribute.cellAccessoryType
        cell.text = attribute.id
        cell.detailFont = attribute.valueFont
        cell.detailText = attribute.value
        return cell
      }
    )
  }

  private func applySnapshot(animate: Bool = true) {
    var snapshot = Snapshot()
    snapshot.appendSections(filteredSections)
    filteredSections.forEach { snapshot.appendItems($0.items, toSection: $0) }
    dataSource.apply(snapshot, animatingDifferences: animate)
  }

  func fetchTransaction() {
    Up.retrieveTransaction(for: transaction) { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(transaction):
          self.display(transaction)
        case let .failure(error):
          self.display(error)
        }
      }
    }
  }

  private func display(_ transaction: TransactionResource) {
    self.transaction = transaction
  }

  private func display(_ error: AFError) {
    tableView.refreshControl?.endRefreshing()
  }
}

// MARK: - UITableViewDelegate

extension TransactionDetailVC: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }

  func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
    guard section == 0, let view = view as? UITableViewHeaderFooterView else { return }
    view.textLabel?.font = .sfMonoRegular(size: .smallSystemFontSize)
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let attribute = dataSource.itemIdentifier(for: indexPath) {
      switch attribute.id {
      case "Account":
        tableView.deselectRow(at: indexPath, animated: true)
        if let account = account {
          let viewController = TransactionsByAccountVC(account: account)
          navigationController?.pushViewController(viewController, animated: true)
        }
      case "Transfer Account":
        tableView.deselectRow(at: indexPath, animated: true)
        if let transferAccount = transferAccount {
          let viewController = TransactionsByAccountVC(account: transferAccount)
          navigationController?.pushViewController(viewController, animated: true)
        }
      case "Parent Category":
        tableView.deselectRow(at: indexPath, animated: true)
        if let parentCategory = parentCategory {
          let viewController = TransactionsByCategoryVC(category: parentCategory)
          navigationController?.pushViewController(viewController, animated: true)
        }
      case "Category":
        tableView.deselectRow(at: indexPath, animated: true)
        if let category = category {
          let viewController = TransactionsByCategoryVC(category: category)
          navigationController?.pushViewController(viewController, animated: true)
        }
      case "Tags":
        let viewController = TransactionTagsVC(transaction: transaction)
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(viewController, animated: true)
      default:
        break
      }
    }
  }

  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    guard let attribute = dataSource.itemIdentifier(for: indexPath), attribute.id != "Tags" else { return nil }
    var elements: [UIMenuElement] = [.copyAttribute(attribute: attribute)]
    if attribute.id == "Category" {
      elements.append(contentsOf: [.editCategory(self), .removeCategory(self, from: transaction)])
    }
    return UIContextMenuConfiguration(elements: elements)
  }
}
