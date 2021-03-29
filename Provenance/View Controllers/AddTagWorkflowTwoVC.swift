import UIKit
import Alamofire
import TinyConstraints
import Rswift

class AddTagWorkflowTwoVC: ViewController {
    var transaction: TransactionResource!
    
    weak var submitActionProxy: UIAlertAction?
    
    let fetchingView = ActivityIndicator(style: .medium)
    let tableViewController = TableViewController(style: .insetGrouped)
    let refreshControl = RefreshControl(frame: .zero)
    let searchController = UISearchController(searchResultsController: nil)
    
    private var textDidChangeObserver: NSObjectProtocol!
    private var prevFilteredTags: [TagResource] = []
    private var tags: [TagResource] = []
    private var tagsErrorResponse: [ErrorObject] = []
    private var tagsError: String = ""
    private var filteredTags: [TagResource] {
        tags.filter { tag in
            searchController.searchBar.text!.isEmpty || tag.id.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    
    @objc private func openAddWorkflow() {
        let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)
        
        let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
        let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]
        
        let titleAttrString = NSMutableAttributedString(string: "New Tag", attributes: titleFont)
        let messageAttrString = NSMutableAttributedString(string: "Enter the name of the new tag.", attributes: messageFont)
        
        ac.setValue(titleAttrString, forKey: "attributedTitle")
        ac.setValue(messageAttrString, forKey: "attributedMessage")
        ac.addTextField { textField in
            textField.delegate = self
            textField.autocapitalizationType = .none
            textField.tintColor = R.color.accentColor()
            textField.autocorrectionType = .no
            
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
            if answer.text != "" {
                let vc = AddTagWorkflowThreeVC(style: .insetGrouped)
                vc.transaction = self.transaction
                vc.tag = answer.text
                self.navigationController?.pushViewController(vc, animated: true)
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
        setupFetchingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchTags()
    }
    
    private func setProperties() {
        title = "Tags"
    }
    
    private func setupNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backButtonDisplayMode = .minimal
    }
    
    private func setupSearch() {
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.delegate = self
        
        definesPresentationContext = true
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
        tableViewController.refreshControl = refreshControl
    }
    
    private func setupFetchingView() {
        view.addSubview(fetchingView)
        
        fetchingView.edgesToSuperview()
    }
    
    private func setupTableView() {
        super.addChild(tableViewController)
        
        view.addSubview(tableViewController.tableView)
        
        tableViewController.tableView.edgesToSuperview()
        
        tableViewController.tableView.dataSource = self
        tableViewController.tableView.delegate = self
        
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tagCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noTagsCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    private func fetchTags() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        AF.request(UpApi.Tags().listTags, method: .get, parameters: pageSize200Param, headers: headers).responseJSON { response in
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Tag.self, from: response.data!) {
                        print("Tags JSON decoding succeeded")
                        self.tags = decodedResponse.data
                        self.tagsError = ""
                        self.tagsErrorResponse = []
                        self.navigationItem.title = "Select Tag"
                        if self.navigationItem.rightBarButtonItem == nil {
                            self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.openAddWorkflow)), animated: true)
                        }
                        if self.fetchingView.isDescendant(of: self.view) {
                            self.fetchingView.removeFromSuperview()
                        }
                        if !self.tableViewController.tableView.isDescendant(of: self.view) {
                            self.setupTableView()
                        }
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                        if self.searchController.isActive {
                            self.prevFilteredTags = self.filteredTags
                        }
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        print("Tags Error JSON decoding succeeded")
                        self.tagsErrorResponse = decodedResponse.errors
                        self.tagsError = ""
                        self.tags = []
                        self.navigationItem.title = "Errors"
                        self.navigationItem.setRightBarButton(nil, animated: true)
                        if self.fetchingView.isDescendant(of: self.view) {
                            self.fetchingView.removeFromSuperview()
                        }
                        if !self.tableViewController.tableView.isDescendant(of: self.view) {
                            self.setupTableView()
                        }
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    } else {
                        print("Tags JSON decoding failed")
                        self.tagsError = "JSON Decoding Failed!"
                        self.tagsErrorResponse = []
                        self.tags = []
                        self.navigationItem.title = "Error"
                        self.navigationItem.setRightBarButton(nil, animated: true)
                        if self.fetchingView.isDescendant(of: self.view) {
                            self.fetchingView.removeFromSuperview()
                        }
                        if !self.tableViewController.tableView.isDescendant(of: self.view) {
                            self.setupTableView()
                        }
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
                    self.tagsError = response.error?.localizedDescription ?? "Unknown Error!"
                    self.tagsErrorResponse = []
                    self.tags = []
                    self.navigationItem.title = "Error"
                    self.navigationItem.setRightBarButton(nil, animated: true)
                    if self.fetchingView.isDescendant(of: self.view) {
                        self.fetchingView.removeFromSuperview()
                    }
                    if !self.tableViewController.tableView.isDescendant(of: self.view) {
                        self.setupTableView()
                    }
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
            }
            self.searchController.searchBar.placeholder = "Search \(self.tags.count.description) \(self.tags.count == 1 ? "Tag" : "Tags")"
        }
    }
}

extension AddTagWorkflowTwoVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.filteredTags.isEmpty && self.tagsError.isEmpty && self.tagsErrorResponse.isEmpty {
            return 1
        } else {
            if !self.tagsError.isEmpty {
                return 1
            } else if !self.tagsErrorResponse.isEmpty {
                return tagsErrorResponse.count
            } else {
                return filteredTags.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tagCell = tableView.dequeueReusableCell(withIdentifier: "tagCell", for: indexPath)
        
        let noTagsCell = tableView.dequeueReusableCell(withIdentifier: "noTagsCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.filteredTags.isEmpty && self.tagsError.isEmpty && self.tagsErrorResponse.isEmpty {
            tableView.separatorStyle = .none
            
            noTagsCell.selectionStyle = .none
            noTagsCell.textLabel?.textAlignment = .center
            noTagsCell.textLabel?.textColor = .white
            noTagsCell.textLabel?.text = "No Tags"
            noTagsCell.textLabel?.font = circularStdBook
            noTagsCell.backgroundColor = .clear
            
            return noTagsCell
        } else {
            tableView.separatorStyle = .singleLine
            
            if !self.tagsError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.font = circularStdBook
                errorStringCell.textLabel?.text = tagsError
                
                return errorStringCell
            } else if !self.tagsErrorResponse.isEmpty {
                let error = tagsErrorResponse[indexPath.row]
                
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .red
                errorObjectCell.textLabel?.font = circularStdBold
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
                errorObjectCell.detailTextLabel?.text = error.detail
                
                return errorObjectCell
            } else {
                let tag = filteredTags[indexPath.row]
                
                tagCell.selectedBackgroundView = bgCellView
                tagCell.accessoryType = .none
                tagCell.textLabel?.font = circularStdBook
                tagCell.textLabel?.text = tag.id
                
                return tagCell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.tagsErrorResponse.isEmpty && self.tagsError.isEmpty && !self.filteredTags.isEmpty {
            let vc = AddTagWorkflowThreeVC(style: .insetGrouped)
            
            vc.transaction = transaction
            vc.tag = filteredTags[indexPath.row].id
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension AddTagWorkflowTwoVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        
        guard let stringRange = Range(range, in: currentText) else { return false }
        
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        return updatedText.count <= 30
    }
}

extension AddTagWorkflowTwoVC: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if self.prevFilteredTags != self.filteredTags {
            self.prevFilteredTags = self.filteredTags
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if self.filteredTags != self.prevFilteredTags {
            self.tableViewController.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
        self.prevFilteredTags = self.filteredTags
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searchBar.text = ""
            self.prevFilteredTags = self.filteredTags
            self.tableViewController.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
}
