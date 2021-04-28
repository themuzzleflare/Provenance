import UIKit
import Alamofire
import TinyConstraints
import Rswift

class AllTagsVC: TableViewController {
    let tableRefreshControl = RefreshControl(frame: .zero)
    let searchController = SearchController(searchResultsController: nil)
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, TagResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, TagResource>
    
    private var tagsStatusCode: Int = 0
    private var tags: [TagResource] = [] {
        didSet {
            applySnapshot()
            refreshControl?.endRefreshing()
            searchController.searchBar.placeholder = "Search \(tags.count.description) \(tags.count == 1 ? "Tag" : "Tags")"
        }
    }
    private var tagsPagination: Pagination = Pagination(prev: nil, next: nil)
    private var tagsErrorResponse: [ErrorObject] = []
    private var tagsError: String = ""
    private var filteredTags: [TagResource] {
        tags.filter { tag in
            searchController.searchBar.text!.isEmpty || tag.id.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    private var filteredTagsList: Tag {
        return Tag(data: filteredTags, links: tagsPagination)
    }
    
    private lazy var dataSource = makeDataSource()
    
    private enum Section: CaseIterable {
        case main
    }
    
    private func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, tag in
                let cell = tableView.dequeueReusableCell(withIdentifier: "tagTableViewCell", for: indexPath) as! BasicTableViewCell
                cell.selectedBackgroundView = selectedBackgroundCellView
                cell.selectionStyle = .default
                cell.accessoryType = .none
                cell.separatorInset = .zero
                cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                cell.textLabel?.text = tag.id
                return cell
            }
        )
        dataSource.defaultRowAnimation = .fade
        return dataSource
    }
    
    private func applySnapshot(animate: Bool = false) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(filteredTagsList.data, toSection: .main)
        if snapshot.itemIdentifiers.isEmpty && tagsError.isEmpty && tagsErrorResponse.isEmpty  {
            if tags.isEmpty && tagsStatusCode == 0 {
                tableView.backgroundView = {
                    let view = UIView(frame: CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: tableView.bounds.width, height: tableView.bounds.height))
                    let loadingIndicator = ActivityIndicator(style: .medium)
                    view.addSubview(loadingIndicator)
                    loadingIndicator.center(in: view)
                    loadingIndicator.startAnimating()
                    return view
                }()
            } else {
                tableView.backgroundView = {
                    let view = UIView(frame: CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: tableView.bounds.width, height: tableView.bounds.height))
                    let label = UILabel()
                    view.addSubview(label)
                    label.center(in: view)
                    label.textAlignment = .center
                    label.textColor = .label
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = "No Tags"
                    return view
                }()
            }
        } else {
            if !tagsError.isEmpty {
                tableView.backgroundView = {
                    let view = UIView(frame: CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: tableView.bounds.width, height: tableView.bounds.height))
                    let label = UILabel()
                    view.addSubview(label)
                    label.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    label.center(in: view)
                    label.textAlignment = .center
                    label.textColor = .label
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = tagsError
                    return view
                }()
            } else if !tagsErrorResponse.isEmpty {
                tableView.backgroundView = {
                    let view = UIView(frame: CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: tableView.bounds.width, height: tableView.bounds.height))
                    let titleLabel = UILabel()
                    let detailLabel = UILabel()
                    let verticalStack = UIStackView()
                    view.addSubview(verticalStack)
                    titleLabel.translatesAutoresizingMaskIntoConstraints = false
                    titleLabel.textAlignment = .center
                    titleLabel.textColor = .systemRed
                    titleLabel.font = R.font.circularStdBold(size: UIFont.labelFontSize)
                    titleLabel.numberOfLines = 0
                    titleLabel.text = tagsErrorResponse.first?.title
                    detailLabel.translatesAutoresizingMaskIntoConstraints = false
                    detailLabel.textAlignment = .center
                    detailLabel.textColor = .label
                    detailLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    detailLabel.numberOfLines = 0
                    detailLabel.text = tagsErrorResponse.first?.detail
                    verticalStack.addArrangedSubview(titleLabel)
                    verticalStack.addArrangedSubview(detailLabel)
                    verticalStack.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    verticalStack.center(in: view)
                    verticalStack.axis = .vertical
                    verticalStack.alignment = .center
                    verticalStack.distribution = .fill
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureProperties()
        configureNavigation()
        configureSearch()
        configureRefreshControl()
        configureTableView()
        applySnapshot()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchTags()
    }
}

private extension AllTagsVC {
    @objc private func appMovedToForeground() {
        fetchTags()
    }

    @objc private func openAddWorkflow() {
        present({let vc = NavigationController(rootViewController: AddTagWorkflowVC(style: .grouped));vc.modalPresentationStyle = .fullScreen;return vc}(), animated: true)
    }

    @objc private func refreshTags() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchTags()
        }
    }
    
    private func configureProperties() {
        title = "Tags"
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.tag(), style: .plain, target: self, action: nil)
        navigationItem.searchController = searchController
    }
    
    private func configureSearch() {
        searchController.searchBar.delegate = self
    }
    
    private func configureRefreshControl() {
        tableRefreshControl.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
    }
    
    private func configureTableView() {
        tableView.refreshControl = tableRefreshControl
        tableView.dataSource = dataSource
        tableView.register(BasicTableViewCell.self, forCellReuseIdentifier: "tagTableViewCell")
    }
    
    private func fetchTags() {
        AF.request(UpAPI.Tags().listTags, method: .get, parameters: pageSize200Param, headers: [acceptJsonHeader, authorisationHeader]).responseJSON { response in
            self.tagsStatusCode = response.response?.statusCode ?? 0
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Tag.self, from: response.data!) {
                        self.tagsError = ""
                        self.tagsErrorResponse = []
                        self.tagsPagination = decodedResponse.links
                        self.tags = decodedResponse.data
                        
                        if self.navigationItem.title != "Tags" {
                            self.navigationItem.title = "Tags"
                        }
                        if self.navigationItem.rightBarButtonItem == nil {
                            self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.openAddWorkflow)), animated: true)
                        }
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        self.tagsErrorResponse = decodedResponse.errors
                        self.tagsError = ""
                        self.tagsPagination = Pagination(prev: nil, next: nil)
                        self.tags = []
                        
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        if self.navigationItem.rightBarButtonItem != nil {
                            self.navigationItem.setRightBarButton(nil, animated: true)
                        }
                    } else {
                        self.tagsError = "JSON Decoding Failed!"
                        self.tagsErrorResponse = []
                        self.tagsPagination = Pagination(prev: nil, next: nil)
                        self.tags = []

                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        if self.navigationItem.rightBarButtonItem != nil {
                            self.navigationItem.setRightBarButton(nil, animated: true)
                        }
                    }
                case .failure:
                    self.tagsError = response.error?.localizedDescription ?? "Unknown Error!"
                    self.tagsErrorResponse = []
                    self.tagsPagination = Pagination(prev: nil, next: nil)
                    self.tags = []

                    if self.navigationItem.title != "Error" {
                        self.navigationItem.title = "Error"
                    }
                    if self.navigationItem.rightBarButtonItem != nil {
                        self.navigationItem.setRightBarButton(nil, animated: true)
                    }
            }
        }
    }
}

extension AllTagsVC {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        navigationController?.pushViewController({let vc = TransactionsByTagVC(style: .grouped);vc.tag = dataSource.itemIdentifier(for: indexPath);return vc}(), animated: true)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy Tag Name", image: R.image.docOnClipboard()) { _ in
                    UIPasteboard.general.string = self.dataSource.itemIdentifier(for: indexPath)!.id
                }
            ])
        }
    }
}

extension AllTagsVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySnapshot(animate: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if !searchBar.text!.isEmpty {
            searchBar.text = ""
            applySnapshot(animate: true)
        }
    }
}
