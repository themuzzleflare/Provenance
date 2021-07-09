import UIKit
import FLAnimatedImage
import SwiftyBeaver
import TinyConstraints
import Rswift

final class TagsVC: UIViewController {
    // MARK: - Properties

    private typealias Snapshot = NSDiffableDataSourceSnapshot<SortedTags, TagResource>

    private lazy var dataSource = makeDataSource()

    private let tableRefreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
        return rc
    }()

    private let searchController = SearchController(searchResultsController: nil)

    private let tableView = UITableView(frame: .zero, style: .plain)

    private var apiKeyObserver: NSKeyValueObservation?
    
    private var noTags: Bool = false

    private var tags: [TagResource] = [] {
        didSet {
            log.info("didSet tags: \(tags.count.description)")

            noTags = tags.isEmpty
            applySnapshot()
            tableView.refreshControl?.endRefreshing()
            searchController.searchBar.placeholder = "Search \(tags.count.description) \(tags.count == 1 ? "Tag" : "Tags")"
        }
    }

    private var tagsError: String = ""

    private var filteredTags: [TagResource] {
        tags.filter { tag in
            searchController.searchBar.text!.isEmpty || tag.id.localizedStandardContains(searchController.searchBar.text!)
        }
    }

    private var groupedTags: [String: [TagResource]] {
        Dictionary(
            grouping: filteredTags,
            by: { String($0.id.prefix(1)) }
        )
    }

    private var keys: [String] {
        groupedTags.keys.sorted()
    }

    private var sortedTags: Array<(key: String, value: Array<TagResource>)> {
        groupedTags.sorted { $0.key < $1.key }
    }

    private var sections: [SortedTags] = []

    private class DataSource: UITableViewDiffableDataSource<SortedTags, TagResource> {
        weak var parent: TagsVC! = nil

        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            guard let firstTag = itemIdentifier(for: IndexPath(item: 0, section: section)) else {
                return nil
            }

            guard let section = snapshot().sectionIdentifier(containingItem: firstTag) else {
                return nil
            }

            return section.id.capitalized
        }

        override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
            return parent.keys.map { $0.capitalized }
        }
    }

    // MARK: - Life Cycle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        dataSource.parent = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        log.debug("viewDidLoad")
        view.addSubview(tableView)
        configureTableView()
        configureProperties()
        configureNavigation()
        configureSearch()
        applySnapshot()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        log.debug("viewDidLayoutSubviews")
        tableView.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        log.debug("viewWillAppear(animated: \(animated.description))")
        fetchTags()
    }
}

// MARK: - Configuration

private extension TagsVC {
    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Tags"
        definesPresentationContext = true

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { [self] object, change in
            fetchTags()
        }
    }
    
    private func configureNavigation() {
        log.verbose("configureNavigation")

        navigationItem.title = "Loading"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.tag())
        navigationItem.searchController = searchController
    }
    
    private func configureSearch() {
        log.verbose("configureSearch")

        searchController.searchBar.delegate = self
    }
    
    private func configureTableView() {
        log.verbose("configureTableView")

        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tagCell")
        tableView.refreshControl = tableRefreshControl
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}

// MARK: - Actions

private extension TagsVC {
    @objc private func appMovedToForeground() {
        log.verbose("appMovedToForeground")

        fetchTags()
    }

    @objc private func openAddWorkflow() {
        log.verbose("openAddWorkflow")

        let vc = NavigationController(rootViewController: AddTagWorkflowVC())

        vc.modalPresentationStyle = .fullScreen

        present(vc, animated: true)
    }

    @objc private func refreshTags() {
        log.verbose("refreshTags")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchTags()
        }
    }

    private func makeDataSource() -> DataSource {
        log.verbose("makeDataSource")

        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, tag in
            let cell = tableView.dequeueReusableCell(withIdentifier: "tagCell", for: indexPath)

            cell.selectedBackgroundView = selectedBackgroundCellView
            cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
            cell.textLabel?.textAlignment = .left
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = tag.id

            return cell
        }
        )
        dataSource.defaultRowAnimation = .automatic
        return dataSource
    }

    private func applySnapshot(animate: Bool = true) {
        log.verbose("applySnapshot(animate: \(animate.description))")

        sections = sortedTags.map { SortedTags(id: $0.key, tags: $0.value) }

        var snapshot = Snapshot()

        snapshot.appendSections(sections)
        sections.forEach { snapshot.appendItems($0.tags, toSection: $0) }

        if snapshot.itemIdentifiers.isEmpty && tagsError.isEmpty {
            if tags.isEmpty && !noTags {
                tableView.backgroundView = {
                    let view = UIView(frame: tableView.bounds)

                    let loadingIndicator = FLAnimatedImageView()

                    view.addSubview(loadingIndicator)

                    loadingIndicator.centerInSuperview()
                    loadingIndicator.width(100)
                    loadingIndicator.height(100)
                    loadingIndicator.animatedImage = upZapSpinTransparentBackground

                    return view
                }()
            } else {
                tableView.backgroundView = {
                    let view = UIView(frame: tableView.bounds)

                    let icon = UIImageView(image: R.image.xmarkDiamond())

                    icon.width(70)
                    icon.height(64)
                    icon.tintColor = .secondaryLabel

                    let label = UILabel()

                    label.translatesAutoresizingMaskIntoConstraints = false
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: 23)
                    label.text = "No Tags"

                    let vStack = UIStackView(arrangedSubviews: [icon, label])

                    view.addSubview(vStack)

                    vStack.horizontalToSuperview(insets: .horizontal(16))
                    vStack.centerInSuperview()
                    vStack.axis = .vertical
                    vStack.alignment = .center
                    vStack.spacing = 10

                    return view
                }()
            }
        } else {
            if !tagsError.isEmpty {
                tableView.backgroundView = {
                    let view = UIView(frame: tableView.bounds)

                    let label = UILabel()

                    view.addSubview(label)

                    label.horizontalToSuperview(insets: .horizontal(16))
                    label.centerInSuperview()
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = tagsError

                    return view
                }()
            } else {
                if tableView.backgroundView != nil {
                    tableView.backgroundView = nil
                }
            }
        }

        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    private func fetchTags() {
        log.verbose("fetchTags")

        if #available(iOS 15.0, *) {
            async {
                do {
                    let tags = try await Up.listTags()
                    
                    display(tags)
                } catch {
                    display(error as! NetworkError)
                }
            }
        } else {
            Up.listTags { [self] result in
                DispatchQueue.main.async {
                    switch result {
                        case .success(let tags):
                            display(tags)
                        case .failure(let error):
                            display(error)
                    }
                }
            }
        }
    }

    private func display(_ tags: [TagResource]) {
        log.verbose("display(tags: \(tags.count.description))")

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
        log.verbose("display(error: \(errorString(for: error)))")

        tagsError = errorString(for: error)
        tags = []

        if navigationItem.title != "Error" {
            navigationItem.title = "Error"
        }
        if navigationItem.rightBarButtonItem != nil {
            navigationItem.setRightBarButton(nil, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate

extension TagsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.debug("tableView(didSelectRowAt indexPath: \(indexPath))")

        tableView.deselectRow(at: indexPath, animated: true)

        if let tag = dataSource.itemIdentifier(for: indexPath) {
            navigationController?.pushViewController(TransactionsByTagVC(tag: tag), animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let tag = dataSource.itemIdentifier(for: indexPath)?.id else {
            return nil
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                UIPasteboard.general.string = tag
            }
            ])
        }
    }
}

// MARK: - UISearchBarDelegate

extension TagsVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        log.debug("searchBar(textDidChange searchText: \(searchText))")
        
        applySnapshot(animate: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        log.debug("searchBarCancelButtonClicked")

        if !searchBar.text!.isEmpty {
            searchBar.text = ""
            applySnapshot(animate: true)
        }
    }
}
