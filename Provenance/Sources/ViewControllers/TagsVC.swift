import IGListKit
import AsyncDisplayKit
import Alamofire

final class TagsVC: ASViewController {
  // MARK: - Properties

  private lazy var searchController = UISearchController(self)

  private lazy var adapter = ListAdapter(updater: ListAdapterUpdater(), viewController: self)

  private let collectionNode = ASCollectionNode(collectionViewLayout: .flowLayout)

  private var apiKeyObserver: NSKeyValueObservation?

  private var noTags: Bool = false

  private var tags = [TagResource]() {
    didSet {
      noTags = tags.isEmpty
      adapter.performUpdates(animated: true)
      collectionNode.view.refreshControl?.endRefreshing()
      searchController.searchBar.placeholder = tags.searchBarPlaceholder
    }
  }

  private var tagsError = String()

  private var filteredTags: [TagResource] {
    return tags.filtered(searchBar: searchController.searchBar)
  }

  // MARK: - Life Cycle

  override init() {
    super.init(node: collectionNode)
    adapter.setASDKCollectionNode(collectionNode)
    adapter.dataSource = self
  }

  deinit {
    removeObservers()
    print("\(#function) \(String(describing: type(of: self)))")
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureObservers()
    configureCollectionNode()
    configureSelf()
    configureNavigation()
    adapter.performUpdates(animated: false)
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
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(appMovedToForeground),
                                           name: .willEnterForegroundNotification,
                                           object: nil)
    apiKeyObserver = UserDefaults.provenance.observe(\.apiKey, options: .new) { [weak self] (_, _) in
      self?.fetchTags()
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

  private func configureCollectionNode() {
    collectionNode.view.refreshControl = UIRefreshControl(self, action: #selector(refreshTags))
  }
}

// MARK: - Actions

private extension TagsVC {
  @objc
  private func appMovedToForeground() {
    fetchTags()
  }

  @objc
  private func addTags() {
    let viewController = NavigationController(rootViewController: .addTagTransactionSelection)
    present(.fullscreen(viewController), animated: true)
  }

  @objc
  private func refreshTags() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.fetchTags()
    }
  }

  private func fetchTags() {
    Up.listTags { (result) in
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
    tagsError = ""
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

// MARK: - ListAdapterDataSource

extension TagsVC: ListAdapterDataSource {
  func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
    return filteredTags.tagSectionModels.sortedMixedModel
  }

  func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
    switch object {
    case is SortedTagSectionModel:
      return TagSectionModelSC()
    default:
      return TagCellModelSC(self)
    }
  }

  func emptyView(for listAdapter: ListAdapter) -> UIView? {
    if filteredTags.isEmpty && tagsError.isEmpty {
      if tags.isEmpty && !noTags {
        return .loadingView(frame: collectionNode.bounds, contentType: .tags)
      } else {
        return .noContentView(frame: collectionNode.bounds, type: .tags)
      }
    } else {
      if !tagsError.isEmpty {
        return .errorView(frame: collectionNode.bounds, text: tagsError)
      } else {
        return nil
      }
    }
  }
}

// MARK: - SelectionDelegate

extension TagsVC: SelectionDelegate {
  func didSelectItem(at indexPath: IndexPath) {
    if let tag = filteredTags.tagSectionCoreModels.sortedMixedCoreModel[indexPath.section] as? TagResource {
      let viewController = TransactionsByTagVC(tag: tag)
      navigationController?.pushViewController(viewController, animated: true)
    }
  }
}

// MARK: - UISearchBarDelegate

extension TagsVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    adapter.performUpdates(animated: true)
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    if searchBar.searchTextField.hasText {
      searchBar.clear()
      adapter.performUpdates(animated: true)
    }
  }
}
