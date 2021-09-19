import UIKit
import IGListKit
import AsyncDisplayKit

final class TagsVC: ASViewController {
  // MARK: - Properties

  private lazy var searchController = UISearchController(self)

  private lazy var tableRefreshControl = UIRefreshControl(self, selector: #selector(refreshTags))

  private let tableNode = ASTableNode(style: .grouped)

  private var apiKeyObserver: NSKeyValueObservation?

  private var noTags: Bool = false

  private var tags = [TagResource]() {
    didSet {
      noTags = tags.isEmpty
      applySnapshot()
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
    configureProperties()
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
  private func configureProperties() {
    title = "Tags"
    definesPresentationContext = true
  }
  
  private func configureObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appMovedToForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
    apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { [weak self] (_, change) in
      guard let weakSelf = self, let value = change.newValue else { return }
      DispatchQueue.main.async {
        weakSelf.fetchTags()
      }
    }
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self)
    apiKeyObserver?.invalidate()
    apiKeyObserver = nil
  }

  private func configureNavigation() {
    navigationItem.title = "Loading"
    navigationItem.largeTitleDisplayMode = .always
    navigationItem.backBarButtonItem = UIBarButtonItem(image: .tag)
    navigationItem.searchController = searchController
  }

  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.refreshControl = tableRefreshControl
  }
}

// MARK: - Actions

private extension TagsVC {
  @objc private func appMovedToForeground() {
    fetchTags()
  }

  @objc private func openAddWorkflow() {
    let vc = NavigationController(rootViewController: AddTagWorkflowVC())
    vc.modalPresentationStyle = .fullScreen
    present(vc, animated: true)
  }

  @objc private func refreshTags() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
      fetchTags()
    }
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
    if navigationItem.title != "Tags" {
      navigationItem.title = "Tags"
    }
    if navigationItem.rightBarButtonItem == nil {
      navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(openAddWorkflow)), animated: true)
    }
  }

  private func display(_ error: NetworkError) {
    tagsError = error.description
    tags = []
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
    let node = TagCellNode(text: filteredTags[indexPath.row].id)
    return {
      node
    }
  }
}

// MARK: - ASTableDelegate

extension TagsVC: ASTableDelegate {
  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    tableNode.deselectRow(at: indexPath, animated: true)
    let tag = filteredTags[indexPath.row]
    navigationController?.pushViewController(TransactionsByTagVC(tag: tag), animated: true)
  }

  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let tag = filteredTags[indexPath.row]
    return UIContextMenuConfiguration(elements: [
      .copyTagName(tag: tag)
    ])
  }
}

// MARK: - UISearchBarDelegate

extension TagsVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    applySnapshot()
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if !searchBar.text!.isEmpty {
      searchBar.clear()
      applySnapshot()
    }
  }
}
