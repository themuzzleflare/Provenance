import IGListKit
import UIKit
import Alamofire

final class TagsVCAlt: ViewController {
  // MARK: - Properties

  private lazy var searchController = UISearchController(self)

  private let tableView = UITableView(frame: .zero, style: .plain)

  private class DataSource: UITableViewDiffableDataSource<SortedTags, String> {
    private weak var parent: TagsVCAlt?

    init(parent: TagsVCAlt, tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<SortedTags, String>.CellProvider) {
      self.parent = parent
      super.init(tableView: tableView, cellProvider: cellProvider)
    }

    convenience init(parent: TagsVCAlt,
                     tableView: UITableView,
                     cellProvider: @escaping UITableViewDiffableDataSource<SortedTags, String>.CellProvider,
                     defaultRowAnimation: UITableView.RowAnimation) {
      self.init(parent: parent, tableView: tableView, cellProvider: cellProvider)
      self.defaultRowAnimation = defaultRowAnimation
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      return parent?.filteredTags.sortedTags[section].id.capitalized
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
      return parent?.filteredTags.sortedTags.sectionIndexTitles
    }
  }

  private typealias Snapshot = NSDiffableDataSourceSnapshot<SortedTags, String>

  private lazy var dataSource = makeDataSource()

  private var apiKeyObserver: NSKeyValueObservation?

  private var noTags: Bool = false

  private var tags = [TagResource]() {
    didSet {
      noTags = tags.isEmpty
      applySnapshot()
      tableView.refreshControl?.endRefreshing()
      searchController.searchBar.placeholder = tags.searchBarPlaceholder
    }
  }

  private var tagsError = String()

  private var oldTagCellModels = [TagCellModel]()

  private var filteredTags: [TagResource] {
    return tags.filtered(searchBar: searchController.searchBar)
  }

  // MARK: - Life Cycle

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
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
    view.addSubview(tableView)
    configureObservers()
    configureTableView()
    configureSelf()
    configureNavigation()
    applySnapshot(animate: false)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tableView.frame = view.bounds
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    fetchTags()
  }
}

// MARK: - Configuration

extension TagsVCAlt {
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

  private func configureTableView() {
    tableView.dataSource = dataSource
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tagCell")
    tableView.refreshControl = UIRefreshControl(self, action: #selector(refreshTags))
    tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }
}

// MARK: - Actions

extension TagsVCAlt {
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

  private func makeDataSource() -> DataSource {
    return DataSource(
      parent: self,
      tableView: tableView,
      cellProvider: { (tableView, indexPath, tag) in
        let cell = tableView.dequeueReusableCell(withIdentifier: "tagCell", for: indexPath)
        cell.textLabel?.font = .circularStdBook(size: .labelFontSize)
        cell.textLabel?.textAlignment = .left
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = tag
        return cell
      },
      defaultRowAnimation: .fade
    )
  }

  private func applySnapshot(animate: Bool = true) {
    var snapshot = Snapshot()

    snapshot.appendSections(filteredTags.sortedTags)
    filteredTags.sortedTags.forEach { snapshot.appendItems($0.tags, toSection: $0) }

    if filteredTags.isEmpty && tagsError.isEmpty {
      if tags.isEmpty && !noTags {
        tableView.backgroundView = .loadingView(frame: tableView.bounds, contentType: .tags)
      } else {
        tableView.backgroundView = .noContentView(frame: tableView.bounds, type: .tags)
      }
    } else {
      if !tagsError.isEmpty {
        tableView.backgroundView = .errorView(frame: tableView.bounds, text: tagsError)
      } else {
        if tableView.backgroundView != nil {
          tableView.backgroundView = nil
        }
      }
    }

    dataSource.apply(snapshot, animatingDifferences: animate)
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

// MARK: - UITableViewDelegate

extension TagsVCAlt: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let tag = filteredTags.tagSectionCoreModels[indexPath.section].tags[indexPath.row]
    let viewController = TransactionsByTagVC(tag: tag)
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(viewController, animated: true)
  }

  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let tag = filteredTags.tagSectionCoreModels[indexPath.section].tags[indexPath.row]
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

extension TagsVCAlt: UISearchBarDelegate {
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
