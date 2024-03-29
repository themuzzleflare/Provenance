import UIKit
import AsyncDisplayKit
import IGListKit
import NotificationBannerSwift
import Alamofire

final class AddTagTagsSelectionVC: ASViewController, UIProtocol {
  // MARK: - Properties

  var state: UIState = .initialLoad {
    didSet {
      if oldValue != state {
        UIUpdates.updateUI(state: state, contentType: .tags, collection: .tableNode(tableNode))
      }
    }
  }

  private var transaction: TransactionResource

  private var fromTransactionTags: Bool

  private lazy var editingBarButtonItem = UIBarButtonItem(title: isEditing ? "Cancel" : "Select",
                                                          style: isEditing ? .done : .plain,
                                                          target: self,
                                                          action: #selector(toggleEditing))

  private lazy var addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                      target: self,
                                                      action: #selector(openAddWorkflow))

  private lazy var selectionBarButtonItem = UIBarButtonItem(title: "Deselect All",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(selectionAction))

  private lazy var selectionLabelBarButtonItem = UIBarButtonItem(title: "\(tableNode.indexPathsForSelectedRows?.count.description ?? "0") of 6 selected")

  private lazy var nextBarButtonItem = UIBarButtonItem(title: "Next",
                                                       style: .plain,
                                                       target: self,
                                                       action: #selector(nextAction))

  private lazy var searchController = UISearchController(self)

  private let tableNode = ASTableNode(style: .plain)

  private var showingBanner: Bool = false

  private var noTags: Bool = false

  private var tags = [TagResource]() {
    didSet {
      noTags = tags.isEmpty
      tableNode.view.refreshControl?.endRefreshing()
      applySnapshot()
      updateToolbarItems()
      searchController.searchBar.placeholder = tags.searchBarPlaceholder
    }
  }

  private var tagsError = String()

  private var oldTagCellModels = [ListDiffable]()

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
    configureSelf()
    configureObserver()
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
    editingBarButtonItem = UIBarButtonItem(title: editing ? "Cancel" : "Select",
                                           style: editing ? .done : .plain,
                                           target: self,
                                           action: #selector(toggleEditing))
    navigationItem.rightBarButtonItems = [addBarButtonItem, editingBarButtonItem]
    navigationItem.title = editing ? "Select Tags" : "Select Tag"
    navigationController?.setToolbarHidden(!editing, animated: true)
  }
}

// MARK: - Configuration

extension AddTagTagsSelectionVC {
  private func configureSelf() {
    title = "Tag Selection"
    definesPresentationContext = true
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

extension AddTagTagsSelectionVC {
  @objc
  private func appMovedToForeground() {
    ASPerformBlockOnMainThread {
      self.fetchTags()
    }
  }

  @objc
  private func closeWorkflow() {
    navigationController?.dismiss(animated: true)
  }

  @objc
  private func selectionAction() {
    tableNode.indexPathsForSelectedRows?.forEach { (indexPath) in
      tableNode.deselectRow(at: indexPath, animated: false)
    }
    updateToolbarItems()
  }

  @objc
  private func nextAction() {
    if let selectedTags = tableNode.indexPathsForSelectedRows?.map({ filteredTags[$0.row] }) {
      let viewController = AddTagConfirmationVC(transaction: transaction, tags: selectedTags)
      navigationController?.pushViewController(viewController, animated: true)
    }
  }

  @objc
  private func textChanged() {
    if let alert = presentedViewController as? UIAlertController, let action = alert.actions.last {
      let text = alert.textFields?.textsJoined ?? ""
      action.isEnabled = !text.isEmpty
    }
  }

  @objc
  private func openAddWorkflow() {
    let alertController = UIAlertController.submitNewTags(self, selector: #selector(textChanged), transaction: transaction)
    present(alertController, animated: true)
  }

  @objc
  private func refreshTags() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.fetchTags()
    }
  }

  @objc
  private func toggleEditing() {
    setEditing(!isEditing, animated: true)
  }

  private func updateToolbarItems() {
    editingBarButtonItem.isEnabled = !filteredTags.isEmpty
    selectionBarButtonItem.isEnabled = tableNode.indexPathsForSelectedRows != nil
    selectionLabelBarButtonItem.title = "\(tableNode.indexPathsForSelectedRows?.count.description ?? "0") of 6 selected"
    selectionLabelBarButtonItem.style = tableNode.indexPathsForSelectedRows?.count == 6 ? .done : .plain
    nextBarButtonItem.isEnabled = tableNode.indexPathsForSelectedRows != nil
  }

  private func applySnapshot(override: Bool = false) {
    UIUpdates.applySnapshot(oldArray: &oldTagCellModels,
                            newArray: filteredTags.cellModels,
                            override: override,
                            state: &state,
                            contents: tags,
                            filteredContents: filteredTags,
                            noContent: noTags,
                            error: tagsError,
                            contentType: .tags,
                            collection: .tableNode(tableNode))
  }

  private func fetchTags() {
    Up.listTags { (result) in
      switch result {
      case let .success(tags):
        self.display(tags)
      case let .failure(error):
        self.display(error)
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

  private func display(_ error: AFError) {
    tagsError = error.underlyingError?.localizedDescription ?? error.localizedDescription
    tags.removeAll()
//    setEditing(false, animated: false)
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
    return {
      TagCellNode(model: tag.cellModel, selection: false)
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
      let notificationBanner = FloatingNotificationBanner(title: "Forbidden",
                                                          subtitle: "You can only select a maximum of 6 tags.",
                                                          style: .danger)
      notificationBanner.delegate = self
      notificationBanner.duration = 1.5
      notificationBanner.show(bannerPosition: .top,
                              cornerRadius: 10,
                              shadowBlurRadius: 5,
                              shadowCornerRadius: 20)
    }
    return nil
  }

  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    switch isEditing {
    case true:
      updateToolbarItems()
    case false:
      let tag = filteredTags[indexPath.row]
      let viewController = AddTagConfirmationVC(transaction: transaction, tags: tag)
      tableNode.deselectRow(at: indexPath, animated: true)
      navigationController?.pushViewController(viewController, animated: true)
    }
  }

  func tableNode(_ tableNode: ASTableNode, didDeselectRowAt indexPath: IndexPath) {
    if isEditing {
      updateToolbarItems()
    }
  }

  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let tag = filteredTags[indexPath.row]
    return isEditing ? nil : UIContextMenuConfiguration(elements: [
      .copyTagName(tag: tag)
    ])
  }
}

// MARK: - UITextFieldDelegate

extension AddTagTagsSelectionVC: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let currentText = textField.text ?? ""
    guard let stringRange = Range(range, in: textField.text ?? "") else { return false }
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
      updateToolbarItems()
    }
  }
}

// MARK: - NotificationBannerDelegate

extension AddTagTagsSelectionVC: NotificationBannerDelegate {
  func notificationBannerWillAppear(_ banner: BaseNotificationBanner) {
    showingBanner = true
  }

  func notificationBannerDidDisappear(_ banner: BaseNotificationBanner) {
    showingBanner = false
  }

  func notificationBannerWillDisappear(_ banner: BaseNotificationBanner) {}

  func notificationBannerDidAppear(_ banner: BaseNotificationBanner) {}
}
