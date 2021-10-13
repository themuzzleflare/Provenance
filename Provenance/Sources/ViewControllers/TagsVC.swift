import IGListDiffKit
import AsyncDisplayKit
import Alamofire

final class TagsVC: ASViewController {
  // MARK: - Properties
  
  private lazy var searchController = UISearchController(self)
  
  private let tableNode = ASTableNode(style: .plain)
  
  private var apiKeyObserver: NSKeyValueObservation?
  
  private var noTags: Bool = false
  
  private var tags = [TagResource]() {
    didSet {
      noTags = tags.isEmpty
      applySnapshot()
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
  
  override init() {
    super.init(node: tableNode)
  }
  
  deinit {
    removeObservers()
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureObservers()
    configureTableNode()
    configureSelf()
    configureNavigation()
    applySnapshot(override: true)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchTags()
  }
}

// MARK: - Configuration

private extension TagsVC {
  private func configureSelf() {
    title = "Tags"
    definesPresentationContext = true
  }
  
  private func configureObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: .willEnterForegroundNotification, object: nil)
    apiKeyObserver = ProvenanceApp.userDefaults.observe(\.apiKey, options: .new) { [weak self] (_, _) in
      guard let weakSelf = self else { return }
      weakSelf.fetchTags()
    }
  }
  
  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .willEnterForegroundNotification, object: nil)
    apiKeyObserver?.invalidate()
    apiKeyObserver = nil
  }
  
  private func configureNavigation() {
    navigationItem.title = "Loading"
    navigationItem.largeTitleDisplayMode = .always
    navigationItem.backBarButtonItem = .tag
    navigationItem.searchController = searchController
  }
  
  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.refreshControl = UIRefreshControl(self, action: #selector(refreshTags))
  }
}

// MARK: - Actions

private extension TagsVC {
  @objc private func appMovedToForeground() {
    fetchTags()
  }
  
  @objc private func addTags() {
    let viewController = NavigationController(rootViewController: .addTagTransactionSelection)
    present(.fullscreen(viewController), animated: true)
  }
  
  @objc private func refreshTags() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.fetchTags()
    }
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
    UpFacade.listTags { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(tags):
          self.display(tags)
        case let .failure(error):
          self.display(error)
        }
      }
    }
  }
  
  private func display(_ tags: [TagResource]) {
    tagsError = .emptyString
    self.tags = tags
    if navigationItem.title != "Tags" {
      navigationItem.title = "Tags"
    }
    if navigationItem.rightBarButtonItem == nil {
      navigationItem.setRightBarButton(.addTags(self, action: #selector(addTags)), animated: true)
    }
  }
  
  private func display(_ error: AFError) {
    tagsError = error.errorDescription ?? error.localizedDescription
    tags.removeAll()
    if navigationItem.title != "Error" {
      navigationItem.title = "Error"
    }
    if navigationItem.rightBarButtonItem != nil {
      navigationItem.setRightBarButton(nil, animated: true)
    }
  }
}

// MARK: - ASTableDataSource

extension TagsVC: ASTableDataSource {
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
}

// MARK: - ASTableDelegate

extension TagsVC: ASTableDelegate {
  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    let tag = filteredTags[indexPath.row]
    let viewController = TransactionsByTagVC(tag: tag)
    tableNode.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(viewController, animated: true)
  }
  
  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let tag = filteredTags[indexPath.row]
    return UIContextMenuConfiguration(
      previewProvider: {
        return TransactionsByTagVC(tag: tag)
      },
      elements: [
        .copyTagName(tag: tag)
      ]
    )
  }
}

// MARK: - UISearchBarDelegate

extension TagsVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    applySnapshot()
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if searchBar.searchTextField.hasText {
      searchBar.clear()
      applySnapshot()
    }
  }
}
