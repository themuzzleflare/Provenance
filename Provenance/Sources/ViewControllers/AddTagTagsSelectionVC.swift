import NotificationBannerSwift
import IGListDiffKit
import AsyncDisplayKit
import Alamofire

final class AddTagTagsSelectionVC: ASViewController {
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
  
  private let tableNode = ASTableNode(style: .plain)
  
  private var showingBanner: Bool = false
  
  private var noTags: Bool = false
  
  private var tags = [TagResource]() {
    didSet {
      noTags = tags.isEmpty
      applySnapshot()
      updateToolbarItems()
      tableNode.view.refreshControl?.endRefreshing()
      searchController.searchBar.placeholder = tags.searchBarPlaceholder
    }
  }
  
  private var tagsError = String()
  
  private var oldTagCellModels = [TagCellModel]()
  
  private var filteredTags: [TagResource] {
    return tags.filtered(searchBar: searchController.searchBar)
  }
  
    // MARK: - Life Cycle
  
  init(transaction: TransactionResource, fromTransactionTags: Bool = false) {
    self.transaction = transaction
    self.fromTransactionTags = fromTransactionTags
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
    configureSelf()
    configureNavigation()
    configureToolbar()
    configureTableNode()
    applySnapshot(override: true)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchTags()
    if fromTransactionTags {
      navigationItem.leftBarButtonItem = .close(self, action: #selector(closeWorkflow))
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

private extension AddTagTagsSelectionVC {
  private func configureSelf() {
    title = "Tag Selection"
    definesPresentationContext = true
  }
  
  private func configureObserver() {
    NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: .willEnterForegroundNotification, object: nil)
  }
  
  private func removeObserver() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForegroundNotification, object: nil)
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
    setToolbarItems([selectionBarButtonItem, .flexibleSpace(), selectionLabelBarButtonItem, .flexibleSpace(), nextBarButtonItem], animated: false)
  }
  
  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.refreshControl = UIRefreshControl(self, action: #selector(refreshTags))
    tableNode.allowsMultipleSelectionDuringEditing = true
  }
}

  // MARK: - Actions

private extension AddTagTagsSelectionVC {
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
    if let selectedTags = tableNode.indexPathsForSelectedRows?.map { filteredTags[$0.row] } {
      let viewController = AddTagConfirmationVC(transaction: transaction, tags: selectedTags)
      navigationController?.pushViewController(viewController, animated: true)
    }
  }
  
  @objc private func addTagsTextFieldChanged() {
    if let alert = presentedViewController as? UIAlertController, let action = alert.actions.last {
      let text = alert.textFields?.textsJoined ?? .emptyString
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
      oldArray: oldTagCellModels,
      newArray: filteredTags.tagCellModels,
      option: .equality
    ).forBatchUpdates()
    if result.hasChanges || override || !tagsError.isEmpty || noTags {
      if filteredTags.isEmpty && tagsError.isEmpty {
        if tags.isEmpty && !noTags {
          tableNode.view.backgroundView = .loadingView(frame: tableNode.bounds, contentType: .tags)
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
        oldTagCellModels = filteredTags.tagCellModels
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
    tagsError = .emptyString
    self.tags = tags
    if navigationItem.title != "Select Tag" || navigationItem.title != "Select Tags" {
      navigationItem.title = isEditing ? "Select Tags" : "Select Tag"
    }
    if navigationItem.rightBarButtonItems == nil {
      navigationItem.setRightBarButtonItems([addBarButtonItem, editingBarButtonItem], animated: true)
    }
  }
  
  private func display(_ error: AFError) {
    tagsError = error.errorDescription ?? error.localizedDescription
    tags.removeAll()
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

extension AddTagTagsSelectionVC: ASTableDataSource {
  func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
    return filteredTags.count
  }
  
  func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
    let tag = filteredTags[indexPath.row]
    let node = TagCellNode(tag: tag)
    return {
      node
    }
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return isEditing
  }
}

  // MARK: - ASTableDelegate

extension AddTagTagsSelectionVC: ASTableDelegate {
  func tableNode(_ tableNode: ASTableNode, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    guard let paths = tableNode.indexPathsForSelectedRows, paths.count == 6 else { return indexPath }
    if !showingBanner {
      let notificationBanner = FloatingNotificationBanner(
        title: "Forbidden",
        subtitle: "You can only select a maximum of 6 tags.",
        style: .danger
      )
      notificationBanner.delegate = self
      notificationBanner.duration = 1.5
      notificationBanner.show(
        bannerPosition: .top,
        cornerRadius: 10,
        shadowBlurRadius: 5,
        shadowCornerRadius: 20
      )
    }
    return nil
  }
  
  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    switch isEditing {
    case true:
      updateToolbarItems()
    case false:
      let tag = filteredTags[indexPath.row]
      let viewController = AddTagConfirmationVC(transaction: transaction, tag: tag)
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

extension AddTagTagsSelectionVC: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let currentText = textField.text ?? .emptyString
    guard let stringRange = Range(range, in: textField.text ?? .emptyString) else { return false }
    let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
    return updatedText.count <= 30
  }
}

  // MARK: - UISearchBarDelegate

extension AddTagTagsSelectionVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    applySnapshot()
    updateToolbarItems()
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if searchBar.searchTextField.hasText {
      searchBar.clear()
      applySnapshot()
    }
  }
}

  // MARK: - NotificationBannerDelegate

extension AddTagTagsSelectionVC: NotificationBannerDelegate {
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
