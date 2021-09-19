import UIKit
import NotificationBannerSwift
import IGListKit
import AsyncDisplayKit

final class AddTagWorkflowTwoVC: ASViewController {
  // MARK: - Properties

  private var transaction: TransactionResource
  
  private var fromTransactionTags: Bool

  private lazy var editingBarButtonItem = UIBarButtonItem(
    title: isEditing ? "Cancel" : "Select",
    style: isEditing ? .done : .plain,
    target: self,
    action: #selector(toggleEditing)
  )

  private lazy var addBarButtonItem = UIBarButtonItem(
    barButtonSystemItem: .add,
    target: self,
    action: #selector(openAddWorkflow)
  )

  private lazy var selectionBarButtonItem = UIBarButtonItem(
    title: "Deselect All",
    style: .plain,
    target: self,
    action: #selector(selectionAction)
  )

  private lazy var selectionLabelBarButtonItem = UIBarButtonItem(
    title: "\(tableNode.indexPathsForSelectedRows?.count.description ?? "0") of 6 selected"
  )

  private lazy var nextBarButtonItem = UIBarButtonItem(
    title: "Next",
    style: .plain,
    target: self,
    action: #selector(nextAction)
  )

  private lazy var searchController = UISearchController(self)

  private let tableNode = ASTableNode(style: .grouped)

  private lazy var tableRefreshControl = UIRefreshControl(self, selector: #selector(refreshTags))

  private var showingBanner: Bool = false

  private var noTags: Bool = false

  private var tags = [TagResource]() {
    didSet {
      noTags = tags.isEmpty
      applySnapshot()
      updateToolbarItems()
      tableNode.view.refreshControl?.endRefreshing()
      searchController.searchBar.placeholder = "Search \(tags.count.description) \(tags.count == 1 ? "Tag" : "Tags")"
    }
  }

  private var tagsError = String()

  private var oldFilteredTags = [TagResource]()

  private var filteredTags: [TagResource] {
    return tags.filtered(searchBar: searchController.searchBar)
  }

  // MARK: - Life Cycle

  init(transaction: TransactionResource, fromTransactionTags: Bool = false) {
    self.transaction = transaction
    self.fromTransactionTags = fromTransactionTags
    super.init(node: tableNode)
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  deinit {
    removeObserver()
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
    fetchTags()
    if fromTransactionTags {
      navigationItem.leftBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .close,
        target: self,
        action: #selector(closeWorkflow))
    }
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
    updateToolbarItems()
    addBarButtonItem.isEnabled = !editing
    editingBarButtonItem = UIBarButtonItem(
      title: editing ? "Cancel" : "Select",
      style: editing ? .done : .plain,
      target: self,
      action: #selector(toggleEditing)
    )
    navigationItem.rightBarButtonItems = [addBarButtonItem, editingBarButtonItem]
    navigationItem.title = editing ? "Select Tags" : "Select Tag"
    navigationController?.setToolbarHidden(!editing, animated: true)
  }
}

// MARK: - Configuration

private extension AddTagWorkflowTwoVC {
  private func configureProperties() {
    title = "Tag Selection"
    definesPresentationContext = true
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
    navigationItem.title = "Loading"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
    navigationItem.backButtonDisplayMode = .minimal
  }

  private func configureToolbar() {
    selectionLabelBarButtonItem.tintColor = .label
    let tItems = [
      selectionBarButtonItem,
      .flexibleSpace(),
      selectionLabelBarButtonItem,
      .flexibleSpace(),
      nextBarButtonItem
    ]
    setToolbarItems(tItems, animated: false)
  }

  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.refreshControl = tableRefreshControl
    tableNode.allowsMultipleSelectionDuringEditing = true
  }
}

// MARK: - Actions

private extension AddTagWorkflowTwoVC {
  @objc private func appMovedToForeground() {
    fetchTags()
  }

  @objc private func closeWorkflow() {
    navigationController?.dismiss(animated: true)
  }

  @objc private func selectionAction() {
    tableNode.indexPathsForSelectedRows?.forEach {
      tableNode.deselectRow(at: $0, animated: false)
    }
    updateToolbarItems()
  }

  @objc private func nextAction() {
    if let tags = tableNode.indexPathsForSelectedRows?.map { filteredTags[$0.row] } {
      let tagsObject = tags.map { TagResource(id: $0.id) }
      navigationController?.pushViewController(AddTagWorkflowThreeVC(transaction: transaction, tags: tagsObject), animated: true)
    }
  }

  @objc private func addTagsTextFieldChanged() {
    if let alert = presentedViewController as? UIAlertController, let action = alert.actions.last {
      let text = alert.textFields?.map { $0.text ?? "" }.joined() ?? ""
      action.isEnabled = !text.isEmpty
    }
  }

  @objc private func openAddWorkflow() {
    let alertController = UIAlertController.submitNewTags(self, selector: #selector(addTagsTextFieldChanged), transaction: transaction)
    present(alertController, animated: true)
  }

  @objc private func refreshTags() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [self] in
      fetchTags()
    })
  }

  @objc private func toggleEditing() {
    setEditing(!isEditing, animated: true)
  }

  private func updateToolbarItems() {
    selectionBarButtonItem.isEnabled = tableNode.indexPathsForSelectedRows != nil
    selectionLabelBarButtonItem.title = "\(tableNode.indexPathsForSelectedRows?.count.description ?? "0") of 6 selected"
    selectionLabelBarButtonItem.style = tableNode.indexPathsForSelectedRows?.count == 6 ? .done : .plain
    nextBarButtonItem.isEnabled = tableNode.indexPathsForSelectedRows != nil
  }

  private func applySnapshot(override: Bool = false) {
    let result = ListDiffPaths(
      fromSection: 0,
      toSection: 0,
      oldArray: oldFilteredTags,
      newArray: filteredTags,
      option: .equality
    ).forBatchUpdates()
    if result.hasChanges || override || !tagsError.isEmpty || noTags {
      if filteredTags.isEmpty && tagsError.isEmpty {
        if tags.isEmpty && !noTags {
          tableNode.view.backgroundView = .loadingView(frame: tableNode.bounds)
        } else {
          tableNode.view.backgroundView = .noContentView(frame: tableNode.bounds, type: .tags)
        }
      } else {
        if !tagsError.isEmpty {
          tableNode.view.backgroundView = .errorView(frame: tableNode.bounds, text: tagsError)
        } else {
          if tableNode.view.backgroundView != nil {
            tableNode.view.backgroundView = nil
          }
        }
      }
      let batchUpdates = { [self] in
        tableNode.deleteRows(at: result.deletes, with: .automatic)
        tableNode.insertRows(at: result.inserts, with: .automatic)
        result.moves.forEach { tableNode.moveRow(at: $0.from, to: $0.to) }
        oldFilteredTags = filteredTags
      }
      tableNode.performBatchUpdates(batchUpdates)
    }
  }

  private func fetchTags() {
    UpFacade.listTags { [self] (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(tags):
          display(tags)
        case let .failure(error):
          display(error)
        }
      }
    }
  }

  private func display(_ tags: [TagResource]) {
    tagsError = ""
    self.tags = tags
    if navigationItem.title != "Select Tag" || navigationItem.title != "Select Tags" {
      navigationItem.title = isEditing ? "Select Tags" : "Select Tag"
    }
    if navigationItem.rightBarButtonItems == nil {
      navigationItem.setRightBarButtonItems([addBarButtonItem, editingBarButtonItem], animated: true)
    }
  }

  private func display(_ error: NetworkError) {
    tagsError = error.description
    tags = []
    setEditing(false, animated: false)
    if navigationItem.title != "Error" {
      navigationItem.title = "Error"
    }
    if navigationItem.rightBarButtonItems != nil {
      navigationItem.setRightBarButtonItems(nil, animated: true)
    }
  }
}

// MARK: - ASTableDataSource

extension AddTagWorkflowTwoVC: ASTableDataSource {
  func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
    return filteredTags.count
  }

  func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
    let node = TagCellNode(text: filteredTags[indexPath.row].id)
    return {
      node
    }
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return isEditing
  }
}

// MARK: - ASTableDelegate

extension AddTagWorkflowTwoVC: ASTableDelegate {
  func tableNode(_ tableNode: ASTableNode, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    guard let paths = tableNode.indexPathsForSelectedRows else { return indexPath }
    switch paths.count {
    case 6:
      if !showingBanner {
        let notificationBanner = FloatingNotificationBanner(
          title: "Forbidden",
          subtitle: "You can only select a maximum of 6 tags.",
          style: .danger
        )
        notificationBanner.delegate = self
        notificationBanner.duration = 0.5
        notificationBanner.show(
          bannerPosition: .bottom,
          cornerRadius: 10,
          shadowBlurRadius: 5,
          shadowCornerRadius: 20
        )
      }
      return nil
    default:
      return indexPath
    }
  }

  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    switch isEditing {
    case true:
      updateToolbarItems()
    case false:
      tableNode.deselectRow(at: indexPath, animated: true)
      let tag = filteredTags[indexPath.row].id
      navigationController?.pushViewController(AddTagWorkflowThreeVC(transaction: transaction, tags: [TagResource(id: tag)]), animated: true)
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

  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    switch isEditing {
    case true:
      return nil
    case false:
      let tag = filteredTags[indexPath.row]
      return UIContextMenuConfiguration(elements: [
        .copyTagName(tag: tag)
      ])
    }
  }
}

// MARK: - UITextFieldDelegate

extension AddTagWorkflowTwoVC: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let currentText = textField.text ?? ""
    guard let stringRange = Range(range, in: textField.text ?? "") else { return false }
    let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
    return updatedText.count <= 30
  }
}

// MARK: - UISearchBarDelegate

extension AddTagWorkflowTwoVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    applySnapshot()
    updateToolbarItems()
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if !searchBar.text!.isEmpty {
      searchBar.clear()
      applySnapshot()
    }
  }
}

// MARK: - NotificationBannerDelegate

extension AddTagWorkflowTwoVC: NotificationBannerDelegate {
  func notificationBannerWillAppear(_ banner: BaseNotificationBanner) {
    showingBanner = true
  }

  func notificationBannerWillDisappear(_ banner: BaseNotificationBanner) {
    return
  }

  func notificationBannerDidAppear(_ banner: BaseNotificationBanner) {
    return
  }

  func notificationBannerDidDisappear(_ banner: BaseNotificationBanner) {
    showingBanner = false
  }
}
