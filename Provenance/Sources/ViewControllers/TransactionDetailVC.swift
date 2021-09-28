import MarqueeLabel
import Alamofire

final class TransactionDetailVC: ViewController {
    // MARK: - Properties
  
  private var transaction: TransactionResource {
    didSet {
      fetchingTasks()
    }
  }
  
  private typealias DataSource = UITableViewDiffableDataSource<DetailSection, DetailItem>
  
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
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureObserver()
    view.addSubview(tableView)
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

private extension TransactionDetailVC {
  private func configureSelf() {
    title = "Transaction Details"
  }
  
  private func configureObserver() {
    NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: .willEnterForegroundNotification, object: nil)
  }
  
  private func removeObserver() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForegroundNotification, object: nil)
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
    navigationItem.setRightBarButton(UIBarButtonItem(image: transaction.attributes.status.uiImage, style: .plain, target: self, action: #selector(openStatusIconHelpView)), animated: false)
    navigationItem.rightBarButtonItem?.tintColor = transaction.attributes.status.uiColour
  }
}

  // MARK: - Actions

private extension TransactionDetailVC {
  @objc private func appMovedToForeground() {
    fetchTransaction()
  }
  
  @objc private func openStatusIconHelpView() {
    let viewController = NavigationController(rootViewController: StatusIconHelpView())
    present(viewController, animated: true)
  }
  
  @objc private func refreshTransaction() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
      fetchTransaction()
    }
  }
  
  private func fetchingTasks() {
    UpFacade.retrieveAccount(for: transaction.relationships.account.data.id) { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(account):
          self.account = account
        case .failure:
          break
        }
      }
    }
    
    if let tAccount = transaction.relationships.transferAccount.data {
      UpFacade.retrieveAccount(for: tAccount.id) { (result) in
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
    
    if let pCategory = transaction.relationships.parentCategory.data {
      UpFacade.retrieveCategory(for: pCategory.id) { (result) in
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
      UpFacade.retrieveCategory(for: category.id) { (result) in
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
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
      tableView.refreshControl?.endRefreshing()
      configureNavigation()
    }
  }
  
  private func makeDataSource() -> DataSource {
    return DataSource(
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
  
  private func fetchTransaction() {
    UpFacade.retrieveTransaction(for: transaction) { [self] (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(transaction):
          display(transaction)
        case let .failure(error):
          display(error)
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
    return UIContextMenuConfiguration(elements: [
      .copyAttribute(attribute: attribute)
    ])
  }
}
