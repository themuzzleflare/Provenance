import UIKit
import Alamofire
import TinyConstraints
import Rswift

class AddTagWorkflowTwoVC: TableViewController {
    var transaction: TransactionResource!
    
    weak var submitActionProxy: UIAlertAction?
    
    let tableRefreshControl = RefreshControl(frame: .zero)
    let searchController = SearchController(searchResultsController: nil)
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, TagResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, TagResource>
    
    private var textDidChangeObserver: NSObjectProtocol!
    private var tagsStatusCode: Int = 0
    private var tagsPagination: Pagination = Pagination(prev: nil, next: nil)
    private var tags: [TagResource] = [] {
        didSet {
            applySnapshot()
            refreshControl?.endRefreshing()
            searchController.searchBar.placeholder = "Search \(tags.count.description) \(tags.count == 1 ? "Tag" : "Tags")"

        }
    }
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
                
                cell.selectedBackgroundView = selectedBackgroundCellView
                cell.accessoryType = .none
                cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                cell.textLabel?.text = tag.id
                
                return cell
            }
        )
    }
    private func applySnapshot(animate: Bool = false) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
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
                if tableView.backgroundView != nil {
                    tableView.backgroundView = nil
                }
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    @objc private func appMovedToForeground() {
        fetchTags()
    }

    @objc private func openAddWorkflow() {
        let ac = UIAlertController(title: "New Tag", message: "Enter the name of the new tag.", preferredStyle: .alert)
        ac.addTextField { textField in
            textField.delegate = self
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.tintColor = R.color.accentColor()
            
            self.textDidChangeObserver = NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: OperationQueue.main) { (notification) in
                if let textField = notification.object as? UITextField {
                    if let text = textField.text {
                        self.submitActionProxy!.isEnabled = text.count >= 1
                    } else {
                        self.submitActionProxy!.isEnabled = false
                    }
                }
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
        let submitAction = UIAlertAction(title: "Next", style: .default) { _ in
            let answer = ac.textFields![0]
            if !answer.text!.isEmpty {
                self.navigationController?.pushViewController({let vc = AddTagWorkflowThreeVC(style: .grouped);vc.transaction = self.transaction;vc.tag = answer.text;return vc}(), animated: true)
            }
        }
        submitAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
        submitAction.isEnabled = false
        submitActionProxy = submitAction
        ac.addAction(cancelAction)
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    @objc private func refreshTags() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchTags()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setProperties()
        setupNavigation()
        setupSearch()
        setupRefreshControl()
        setupTableView()
        applySnapshot()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchTags()
    }
    
    private func setProperties() {
        title = "Tags"
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func setupNavigation() {
        navigationItem.title = "Loading"
        navigationItem.searchController = searchController
    }
    
    private func setupSearch() {
        searchController.searchBar.delegate = self
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
        AF.request(UpAPI.Tags().listTags, method: .get, parameters: pageSize200Param, headers: [acceptJsonHeader, authorisationHeader]).responseJSON { response in
            self.tagsStatusCode = response.response?.statusCode ?? 0
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Tag.self, from: response.data!) {
                        self.tags = decodedResponse.data
                        self.tagsPagination = decodedResponse.links
                        self.tagsError = ""
                        self.tagsErrorResponse = []
                        
                        if self.navigationItem.title != "Select Tag" {
                            self.navigationItem.title = "Select Tag"
                        }
                        if self.navigationItem.rightBarButtonItem == nil {
                            self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.openAddWorkflow)), animated: true)
                        }
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        self.tagsErrorResponse = decodedResponse.errors
                        self.tagsError = ""
                        self.tags = []
                        self.tagsPagination = Pagination(prev: nil, next: nil)
                        
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        if self.navigationItem.rightBarButtonItem != nil {
                            self.navigationItem.setRightBarButton(nil, animated: true)
                        }
                    } else {
                        self.tagsError = "JSON Decoding Failed!"
                        self.tagsErrorResponse = []
                        self.tags = []
                        self.tagsPagination = Pagination(prev: nil, next: nil)

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
                    self.tags = []
                    self.tagsPagination = Pagination(prev: nil, next: nil)
                    
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

extension AddTagWorkflowTwoVC {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        navigationController?.pushViewController({let vc = AddTagWorkflowThreeVC(style: .grouped);vc.transaction = transaction;vc.tag = dataSource.itemIdentifier(for: indexPath)!.id;return vc}(), animated: true)
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

extension AddTagWorkflowTwoVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: textField.text ?? "") else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= 30
    }
}

extension AddTagWorkflowTwoVC: UISearchBarDelegate {
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
