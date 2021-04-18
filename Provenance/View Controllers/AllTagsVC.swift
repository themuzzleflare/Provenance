import UIKit
import Alamofire
import TinyConstraints
import Rswift

class AllTagsVC: TableViewController {
    let tableRefreshControl = RefreshControl(frame: .zero)
    let searchController = UISearchController(searchResultsController: nil)
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, TagResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, TagResource>
    
    private var tagsStatusCode: Int = 0
    private var tags: [TagResource] = []
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
        return DataSource(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, tag in
                let cell = tableView.dequeueReusableCell(withIdentifier: "tagTableViewCell", for: indexPath) as! BasicTableViewCell
                
                cell.selectedBackgroundView = bgCellView
                cell.accessoryType = .none
                cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                cell.textLabel?.text = tag.id
                
                return cell
            }
        )
    }
    
    private func applySnapshot(animate: Bool = false) {
        var snapshot = Snapshot()
        
        snapshot.appendSections(Section.allCases)
        
        snapshot.appendItems(filteredTagsList.data, toSection: .main)
        
        if snapshot.itemIdentifiers.isEmpty && tagsError.isEmpty && tagsErrorResponse.isEmpty  {
            if tags.isEmpty && tagsStatusCode == 0 {
                tableView.backgroundView = {
                    let view = UIView()
                    
                    let loadingIndicator = ActivityIndicator(style: .medium)
                    view.addSubview(loadingIndicator)
                    
                    loadingIndicator.center(in: view)
                    
                    loadingIndicator.startAnimating()
                    
                    return view
                }()
            } else {
                tableView.backgroundView = {
                    let view = UIView()
                    
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
                    let view = UIView()
                    
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
                    let view = UIView()
                    
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
                tableView.backgroundView = nil
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: animate)
    }
    
    @objc private func openAddWorkflow() {
        let vc = R.storyboard.addTagWorkflowVC.addTagWorkflowNavigation()!
        
        present(vc, animated: true)
    }
    @objc private func refreshTags() {
        #if targetEnvironment(macCatalyst)
        let loadingView = ActivityIndicator(style: .medium)
        
        navigationItem.setLeftBarButton(UIBarButtonItem(customView: loadingView), animated: true)
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchTags()
        }
    }
    
    @IBAction func workflowClosed(unwindSegue: UIStoryboardSegue) {
        fetchTags()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigation()
        setupSearch()
        setupRefreshControl()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        applySnapshot()
        
        fetchTags()
    }
    
    private func setProperties() {
        title = "Tags"
        definesPresentationContext = true
    }
    
    private func setupNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.tag(), style: .plain, target: self, action: nil)
        
        #if targetEnvironment(macCatalyst)
        navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTags)), animated: true)
        #endif
        
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupSearch() {
        searchController.delegate = self
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        
        searchController.searchBar.delegate = self
        
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
    }
    
    private func setupRefreshControl() {
        tableRefreshControl.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
    }
    
    private func setupTableView() {
        tableView.refreshControl = tableRefreshControl
        tableView.dataSource = dataSource
        tableView.register(BasicTableViewCell.self, forCellReuseIdentifier: "tagTableViewCell")
    }
    
    private func fetchTags() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        
        AF.request(UpApi.Tags().listTags, method: .get, parameters: pageSize200Param, headers: headers).responseJSON { response in
            self.tagsStatusCode = response.response?.statusCode ?? 0
            
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Tag.self, from: response.data!) {
                        self.tags = decodedResponse.data
                        self.tagsPagination = decodedResponse.links
                        self.tagsError = ""
                        self.tagsErrorResponse = []
                        
                        if !decodedResponse.data.isEmpty {
                            if self.navigationItem.searchController == nil {
                                self.navigationItem.searchController = self.searchController
                            }
                        } else {
                            if self.navigationItem.searchController != nil {
                                self.navigationItem.searchController = nil
                            }
                        }
                        
                        if self.navigationItem.title != "Tags" {
                            self.navigationItem.title = "Tags"
                        }
                        if self.navigationItem.rightBarButtonItem == nil {
                            self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.openAddWorkflow)), animated: true)
                        }
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTags)), animated: true)
                        #endif
                        
                        self.applySnapshot()
                        self.refreshControl?.endRefreshing()
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        self.tagsErrorResponse = decodedResponse.errors
                        self.tagsError = ""
                        self.tags = []
                        self.tagsPagination = Pagination(prev: nil, next: nil)
                        
                        if self.navigationItem.searchController != nil {
                            self.navigationItem.searchController = nil
                        }
                        
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        if self.navigationItem.rightBarButtonItem != nil {
                            self.navigationItem.setRightBarButton(nil, animated: true)
                        }
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTags)), animated: true)
                        #endif
                        
                        self.applySnapshot()
                        self.refreshControl?.endRefreshing()
                    } else {
                        self.tagsError = "JSON Decoding Failed!"
                        self.tagsErrorResponse = []
                        self.tags = []
                        self.tagsPagination = Pagination(prev: nil, next: nil)
                        
                        if self.navigationItem.searchController != nil {
                            self.navigationItem.searchController = nil
                        }
                        
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        if self.navigationItem.rightBarButtonItem != nil {
                            self.navigationItem.setRightBarButton(nil, animated: true)
                        }
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTags)), animated: true)
                        #endif
                        
                        self.applySnapshot()
                        self.refreshControl?.endRefreshing()
                    }
                case .failure:
                    self.tagsError = response.error?.localizedDescription ?? "Unknown Error!"
                    self.tagsErrorResponse = []
                    self.tags = []
                    self.tagsPagination = Pagination(prev: nil, next: nil)
                    
                    if self.navigationItem.searchController != nil {
                        self.navigationItem.searchController = nil
                    }
                    
                    if self.navigationItem.title != "Error" {
                        self.navigationItem.title = "Error"
                    }
                    if self.navigationItem.rightBarButtonItem != nil {
                        self.navigationItem.setRightBarButton(nil, animated: true)
                    }
                    
                    #if targetEnvironment(macCatalyst)
                    self.navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTags)), animated: true)
                    #endif
                    
                    self.applySnapshot()
                    self.refreshControl?.endRefreshing()
            }
            self.searchController.searchBar.placeholder = "Search \(self.tags.count.description) \(self.tags.count == 1 ? "Tag" : "Tags")"
        }
    }
}

extension AllTagsVC {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        navigationController?.pushViewController({let vc = TransactionsByTagVC(style: .grouped);vc.tag = dataSource.itemIdentifier(for: indexPath)!;return vc}(), animated: true)
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

extension AllTagsVC: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySnapshot()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searchBar.text = ""
            applySnapshot()
        }
    }
}
