import UIKit
import NotificationBannerSwift
import IGListKit
import AsyncDisplayKit

final class TransactionTagsVC: ASViewController {
    // MARK: - Properties
  
  private var transaction: TransactionResource {
    didSet {
      if transaction.relationships.tags.data.isEmpty {
        navigationController?.popViewController(animated: true)
      } else {
        applySnapshot()
        updateToolbarItems()
        tableNode.view.refreshControl?.endRefreshing()
      }
    }
  }
  
  private var oldTags = [TagResource]()
  
  private var tags: [TagResource] {
    return transaction.relationships.tags.data.tagResources
  }
  
  private lazy var addBarButtonItem = UIBarButtonItem(
    barButtonSystemItem: .add,
    target: self,
    action: #selector(openAddWorkflow)
  )
  
  private lazy var selectionBarButtonItem = UIBarButtonItem(
    title: "Select All",
    style: .plain,
    target: self,
    action: #selector(selectionAction)
  )
  
  private lazy var removeAllBarButtonItem = UIBarButtonItem(
    title: "Remove All",
    style: .plain,
    target: self,
    action: #selector(removeAllTags)
  )
  
  private lazy var removeBarButtonItem = UIBarButtonItem(
    barButtonSystemItem: .trash,
    target: self,
    action: #selector(removeTags)
  )
  
  private let tableNode = ASTableNode(style: .grouped)
  
  private lazy var tableRefreshControl = UIRefreshControl(self, selector: #selector(refreshTags))
  
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
    configureObserver()
    configureProperties()
    configureNavigation()
    configureToolbar()
    configureTableNode()
    applySnapshot(override: true)
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
    addBarButtonItem.isEnabled = !editing
    updateToolbarItems()
    navigationController?.setToolbarHidden(!editing, animated: true)
  }
}

  // MARK: - Configuration

private extension TransactionTagsVC {
  private func configureProperties() {
    title = "Transaction Tags"
  }
  
  private func configureObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appMovedToForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
  }
  
  private func removeObserver() {
    NotificationCenter.default.removeObserver(self)
  }
  
  private func configureNavigation() {
    navigationItem.title = "Tags"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.backBarButtonItem = UIBarButtonItem(image: .tag)
    navigationItem.rightBarButtonItems = [addBarButtonItem, editButtonItem]
  }
  
  private func configureToolbar() {
    setToolbarItems([selectionBarButtonItem, removeAllBarButtonItem, .flexibleSpace(), removeBarButtonItem], animated: false)
  }
  
  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.refreshControl = tableRefreshControl
    tableNode.allowsMultipleSelectionDuringEditing = true
    tableNode.view.showsVerticalScrollIndicator = false
  }
}

  // MARK: - Actions

private extension TransactionTagsVC {
  @objc private func appMovedToForeground() {
    fetchTransaction()
  }
  
  @objc private func openAddWorkflow() {
    let viewController = NavigationController(rootViewController: AddTagWorkflowTwoVC(transaction: transaction, fromTransactionTags: true))
    viewController.modalPresentationStyle = .fullScreen
    present(viewController, animated: true)
  }
  
  @objc private func refreshTags() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
      fetchTransaction()
    }
  }
  
  @objc private func selectionAction() {
    switch tableNode.indexPathsForSelectedRows?.count {
    case tags.count:
      tableNode.indexPathsForSelectedRows?.forEach { tableNode.deselectRow(at: $0, animated: false) }
    default:
      let indexes = tableNode.indexPathsForVisibleRows()
      indexes.forEach { tableNode.selectRow(at: $0, animated: false, scrollPosition: .none) }
    }
    updateToolbarItems()
  }
  
  @objc private func removeTags() {
    if let selectedTags = tableNode.indexPathsForSelectedRows?.map { tags[$0.row] } {
      let alertController = UIAlertController(
        title: nil,
        message: "Are you sure you want to remove \"\(selectedTags.joinedWithComma)\" from \"\(transaction.attributes.description)\"?",
        preferredStyle: .actionSheet
      )
      let confirmAction = UIAlertAction(
        title: "Remove",
        style: .destructive,
        handler: { [self] (_) in
          UpFacade.modifyTags(
            removing: selectedTags,
            from: transaction,
            completion: { (error) in
              DispatchQueue.main.async {
                switch error {
                case .none:
                  GrowingNotificationBanner(
                    title: "Success",
                    subtitle: "\(selectedTags.joinedWithComma) was removed from \(transaction.attributes.description).",
                    style: .success
                  ).show()
                  fetchTransaction()
                default:
                  GrowingNotificationBanner(
                    title: "Failed",
                    subtitle: error!.description,
                    style: .danger
                  ).show()
                }
              }
            }
          )
        }
      )
      alertController.addAction(confirmAction)
      alertController.addAction(.cancel)
      present(alertController, animated: true)
    }
  }
  
  @objc private func removeAllTags() {
    let alertController = UIAlertController(
      title: nil,
      message: "Are you sure you want to remove \"\(tags.joinedWithComma)\" from \"\(transaction.attributes.description)\"?",
      preferredStyle: .actionSheet
    )
    let confirmAction = UIAlertAction(
      title: "Remove",
      style: .destructive,
      handler: { [self] (_) in
        UpFacade.modifyTags(
          removing: tags,
          from: transaction,
          completion: { (error) in
            DispatchQueue.main.async {
              switch error {
              case .none:
                GrowingNotificationBanner(
                  title: "Success",
                  subtitle: "\(tags.joinedWithComma) was removed from \(transaction.attributes.description).",
                  style: .success
                ).show()
                fetchTransaction()
              default:
                GrowingNotificationBanner(
                  title: "Failed",
                  subtitle: error!.description,
                  style: .danger
                ).show()
              }
            }
          }
        )
      }
    )
    alertController.addAction(confirmAction)
    alertController.addAction(.cancel)
    present(alertController, animated: true)
  }
  
  private func updateToolbarItems() {
    selectionBarButtonItem.title = tableNode.indexPathsForSelectedRows?.count == tags.count ? "Deselect All" : "Select All"
    removeAllBarButtonItem.isEnabled = tableNode.indexPathsForSelectedRows?.count != tags.count
    removeBarButtonItem.isEnabled = tableNode.indexPathsForSelectedRows != nil
  }
  
  private func applySnapshot(override: Bool = false) {
    let result = ListDiffPaths(
      fromSection: 0,
      toSection: 0,
      oldArray: oldTags,
      newArray: tags,
      option: .equality
    ).forBatchUpdates()
    if result.hasChanges || override {
      let batchUpdates = { [self] in
        tableNode.deleteRows(at: result.deletes, with: .automatic)
        tableNode.insertRows(at: result.inserts, with: .automatic)
        result.moves.forEach { tableNode.moveRow(at: $0.from, to: $0.to) }
        oldTags = tags
      }
      tableNode.performBatchUpdates(batchUpdates)
    }
  }
  
  private func fetchTransaction() {
    UpFacade.retrieveTransaction(for: transaction) { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(transaction):
          self.transaction = transaction
        case .failure:
          self.tableNode.view.refreshControl?.endRefreshing()
        }
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
    let node = TagCellNode(tag: tag)
    return {
      node
    }
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    let tag = tags[indexPath.row]
    switch editingStyle {
    case .delete:
      let alertController = UIAlertController(
        title: nil,
        message: "Are you sure you want to remove \"\(tag.id)\" from \"\(transaction.attributes.description)\"?",
        preferredStyle: .actionSheet
      )
      let confirmAction = UIAlertAction(
        title: "Remove",
        style: .destructive,
        handler: { [self] (_) in
          UpFacade.modifyTags(
            removing: tag,
            from: transaction,
            completion: { (error) in
              DispatchQueue.main.async {
                switch error {
                case .none:
                  GrowingNotificationBanner(
                    title: "Success",
                    subtitle: "\(tag.id) was removed from \(transaction.attributes.description).",
                    style: .success
                  ).show()
                  fetchTransaction()
                default:
                  GrowingNotificationBanner(
                    title: "Failed",
                    subtitle: error!.description,
                    style: .danger
                  ).show()
                }
              }
            }
          )
        }
      )
      alertController.addAction(confirmAction)
      alertController.addAction(.cancel)
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
    switch isEditing {
    case true:
      updateToolbarItems()
    case false:
      break
    }
  }
  
  func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
    return isEditing
  }
  
  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    return .delete
  }
  
  func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
    return "Remove"
  }
  
  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    switch isEditing {
    case true:
      return nil
    case false:
      let tag = tags[indexPath.row]
      return UIContextMenuConfiguration(
        identifier: nil,
        previewProvider: nil,
        actionProvider: { (_) in
          UIMenu(
            children: [
              UIAction(
                title: "Copy",
                image: .docOnClipboard,
                handler: { (_) in
                  UIPasteboard.general.string = tag.id
                }
              ),
              UIAction(
                title: "Remove",
                image: .trash,
                attributes: .destructive,
                handler: { [self] (_) in
                  let alertController = UIAlertController(
                    title: nil,
                    message: "Are you sure you want to remove \"\(tag.id)\" from \"\(transaction.attributes.description)\"?",
                    preferredStyle: .actionSheet
                  )
                  let confirmAction = UIAlertAction(
                    title: "Remove",
                    style: .destructive,
                    handler: { (_) in
                      UpFacade.modifyTags(
                        removing: tag,
                        from: transaction,
                        completion: { (error) in
                          DispatchQueue.main.async {
                            switch error {
                            case .none:
                              GrowingNotificationBanner(
                                title: "Success",
                                subtitle: "\(tag.id) was removed from \(transaction.attributes.description).",
                                style: .success
                              ).show()
                              fetchTransaction()
                            default:
                              GrowingNotificationBanner(
                                title: "Failed",
                                subtitle: error!.description,
                                style: .danger
                              ).show()
                            }
                          }
                        }
                      )
                    }
                  )
                  alertController.addAction(confirmAction)
                  alertController.addAction(.cancel)
                  present(alertController, animated: true)
                }
              )
            ]
          )
        }
      )
    }
  }
}
