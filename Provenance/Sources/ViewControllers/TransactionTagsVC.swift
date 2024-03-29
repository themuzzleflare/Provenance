import UIKit
import AsyncDisplayKit
import IGListKit

final class TransactionTagsVC: ASViewController {
  // MARK: - Properties

  private var transaction: TransactionResource {
    didSet {
      if transaction.relationships.tags.data.isEmpty {
        navigationController?.popViewController(animated: true)
      } else {
        tableNode.view.refreshControl?.endRefreshing()
        applySnapshot()
        updateToolbarItems()
        addBarButtonItem.isEnabled = !isEditing && tags.count < 6
      }
    }
  }

  private var oldTagCellModels = [TagCellModel]()

  private var tags: [TagResource] {
    return transaction.relationships.tags.data.tagResources
  }

  private lazy var addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                      target: self,
                                                      action: #selector(addTags))

  private lazy var selectionBarButtonItem = UIBarButtonItem(title: "Select All",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(selectionAction))

  private lazy var removeAllBarButtonItem = UIBarButtonItem(title: "Remove All",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(removeAllTags))

  private lazy var removeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash,
                                                         target: self,
                                                         action: #selector(removeTags))

  private let tableNode = ASTableNode(style: .plain)

  // MARK: - Life Cycle

  init(transaction: TransactionResource) {
    self.transaction = transaction
    super.init(node: tableNode)
  }

  deinit {
    removeObserver()
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureSelf()
    configureObserver()
    configureNavigation()
    configureToolbar()
    configureTableNode()
    applySnapshot()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchTransaction()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    navigationController?.setToolbarHidden(!isEditing, animated: true)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setToolbarHidden(true, animated: false)
  }

  override func setEditing(_ editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    tableNode.view.setEditing(editing, animated: animated)
    addBarButtonItem.isEnabled = !editing && tags.count < 6
    updateToolbarItems()
    navigationController?.setToolbarHidden(!editing, animated: true)
  }
}

// MARK: - Configuration

extension TransactionTagsVC {
  private func configureSelf() {
    title = "Transaction Tags"
  }

  private func configureObserver() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(appMovedToForeground),
                                           name: .willEnterForeground,
                                           object: nil)
  }

  private func removeObserver() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForeground, object: nil)
  }

  private func configureNavigation() {
    navigationItem.title = "Tags"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.backBarButtonItem = .tag
    navigationItem.rightBarButtonItems = [addBarButtonItem, editButtonItem]
  }

  private func configureToolbar() {
    setToolbarItems([selectionBarButtonItem, removeAllBarButtonItem, .flexibleSpace(), removeBarButtonItem], animated: false)
  }

  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.refreshControl = UIRefreshControl(self, action: #selector(refreshTags))
    tableNode.allowsMultipleSelectionDuringEditing = true
    tableNode.view.showsVerticalScrollIndicator = false
  }
}

// MARK: - Actions

extension TransactionTagsVC {
  @objc
  private func appMovedToForeground() {
    ASPerformBlockOnMainThread {
      self.fetchTransaction()
    }
  }

  @objc
  private func addTags() {
    let viewController = NavigationController(rootViewController: AddTagTagsSelectionVC(transaction: transaction, fromTransactionTags: true))
    present(.fullscreen(viewController), animated: true)
  }

  @objc
  private func refreshTags() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.fetchTransaction()
    }
  }

  @objc
  private func selectionAction() {
    switch tableNode.indexPathsForSelectedRows?.count {
    case tags.count:
      tableNode.indexPathsForSelectedRows?.forEach { tableNode.deselectRow(at: $0, animated: false) }
    default:
      let indexes = tableNode.indexPathsForVisibleRows()
      indexes.forEach { tableNode.selectRow(at: $0, animated: false, scrollPosition: .none) }
    }
    updateToolbarItems()
  }

  @objc
  private func removeTags() {
    if let selectedTags = tableNode.indexPathsForSelectedRows?.map({ tags[$0.row] }) {
      let alertController = UIAlertController.removeTagsFromTransaction(self, removing: selectedTags, from: transaction)
      present(alertController, animated: true)
    }
  }

  @objc
  private func removeAllTags() {
    let alertController = UIAlertController.removeTagsFromTransaction(self, removing: tags, from: transaction)
    present(alertController, animated: true)
  }

  private func updateToolbarItems() {
    selectionBarButtonItem.title = tableNode.indexPathsForSelectedRows?.count == tags.count ? "Deselect All" : "Select All"
    removeAllBarButtonItem.isEnabled = tableNode.indexPathsForSelectedRows?.count != tags.count
    removeBarButtonItem.isEnabled = tableNode.indexPathsForSelectedRows != nil
  }

  private func applySnapshot() {
    let result = ListDiffPaths(fromSection: 0,
                               toSection: 0,
                               oldArray: oldTagCellModels,
                               newArray: tags.cellModels,
                               option: .equality).forBatchUpdates()

    if result.hasChanges {
      tableNode.performBatchUpdates {
        tableNode.deleteRows(at: result.deletes, with: .fade)
        tableNode.insertRows(at: result.inserts, with: .fade)

        oldTagCellModels = tags.cellModels
      } completion: { (bool) in
        print("completion: \(bool.description)")
      }
    }
  }

  func fetchTransaction() {
    Up.retrieveTransaction(for: transaction) { (result) in
      switch result {
      case let .success(transaction):
        self.transaction = transaction
      case .failure:
        self.tableNode.view.refreshControl?.endRefreshing()
      }
    }
  }
}

// MARK: - ASTableDataSource

extension TransactionTagsVC: ASTableDataSource {
  func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
    return tags.count
  }

  func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
    let tag = tags[indexPath.row]
    return {
      TagCellNode(model: tag.cellModel, selection: false)
    }
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    switch editingStyle {
    case .delete:
      let tag = tags[indexPath.row]
      let alertController = UIAlertController.removeTagFromTransaction(self, removing: tag, from: transaction)
      present(alertController, animated: true)
    default:
      break
    }
  }
}

// MARK: - ASTableDelegate

extension TransactionTagsVC: ASTableDelegate {
  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    switch isEditing {
    case true:
      updateToolbarItems()
    case false:
      let tag = tags[indexPath.row]
      let viewController = TransactionsByTagVC(tag: tag)
      tableNode.deselectRow(at: indexPath, animated: true)
      navigationController?.pushViewController(viewController, animated: true)
    }
  }

  func tableNode(_ tableNode: ASTableNode, didDeselectRowAt indexPath: IndexPath) {
    if isEditing {
      updateToolbarItems()
    }
  }

  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    return .delete
  }

  func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
    return "Remove"
  }

  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let tag = tags[indexPath.row]
    return isEditing ? nil : UIContextMenuConfiguration(elements: [
      .copyTagName(tag: tag),
      .removeTagFromTransaction(self, removing: tag, from: transaction)
    ])
  }
}
