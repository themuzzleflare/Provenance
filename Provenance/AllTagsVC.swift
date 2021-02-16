import UIKit
import Alamofire

class AllTagsVC: UIViewController, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    let fetchingView: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    let tableViewController: UITableViewController = UITableViewController(style: .grouped)
    
    let circularStdBook = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)!
    let circularStdBold = UIFont(name: "CircularStd-Bold", size: UIFont.labelFontSize)!
    
    lazy var refreshControl: UIRefreshControl = UIRefreshControl()
    lazy var searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    lazy var tags: [TagResource] = []
    lazy var tagsErrorResponse: [ErrorObject] = []
    lazy var tagsError: String = ""
    lazy var filteredTags: [TagResource] = []
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredTags = tags.filter { searchController.searchBar.text!.isEmpty || $0.id.localizedStandardContains(searchController.searchBar.text!) }
        tableViewController.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.addChild(tableViewController)
        
        view.backgroundColor = .systemBackground
        
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        
        definesPresentationContext = true
        
        title = "Tags"
        navigationItem.searchController = searchController
        navigationItem.title = "Loading"
        navigationItem.hidesSearchBarWhenScrolling = false
        
        tableViewController.clearsSelectionOnViewWillAppear = true
        tableViewController.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
        
        setupFetchingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        listTags()
    }
    
    @objc private func openAddWorkflow() {
        let vc = UINavigationController(rootViewController: AddTagWorkflowVC())
        present(vc, animated: true)
    }
    
    @objc private func refreshTags() {
        listTags()
    }
    
    func setupFetchingView() {
        view.addSubview(fetchingView)
        
        fetchingView.translatesAutoresizingMaskIntoConstraints = false
        fetchingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        fetchingView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        fetchingView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        fetchingView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        fetchingView.hidesWhenStopped = true
        
        fetchingView.startAnimating()
    }
    
    func setupTableView() {
        view.addSubview(tableViewController.tableView)
        
        tableViewController.tableView.translatesAutoresizingMaskIntoConstraints = false
        tableViewController.tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableViewController.tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableViewController.tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableViewController.tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        tableViewController.tableView.dataSource = self
        tableViewController.tableView.delegate = self
        
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tagCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noTagsCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    func listTags() {
        let urlString = "https://api.up.com.au/api/v1/tags"
        let parameters: Parameters = ["page[size]":"200"]
        let headers: HTTPHeaders = [
            "Accept": "application/json",
            "Authorization": "Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")"
        ]
        AF.request(urlString, method: .get, parameters: parameters, headers: headers).responseJSON { response in
            if response.error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Tag.self, from: response.data!) {
                    print("Tags JSON Decoding Succeeded!")
                    self.tags = decodedResponse.data
                    self.filteredTags = self.tags.filter { self.searchController.searchBar.text!.isEmpty || $0.id.localizedStandardContains(self.searchController.searchBar.text!) }
                    self.tagsError = ""
                    self.tagsErrorResponse = []
                    self.navigationItem.title = "Tags"
                    self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.openAddWorkflow)), animated: true)
                    self.fetchingView.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                    print("Tags Error JSON Decoding Succeeded!")
                    self.tagsErrorResponse = decodedResponse.errors
                    self.tagsError = ""
                    self.tags = []
                    self.navigationItem.title = "Errors"
                    self.navigationItem.setRightBarButton(nil, animated: true)
                    self.fetchingView.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                } else {
                    print("Tags JSON Decoding Failed!")
                    self.tagsError = "JSON Decoding Failed!"
                    self.tagsErrorResponse = []
                    self.tags = []
                    self.navigationItem.title = "Error"
                    self.navigationItem.setRightBarButton(nil, animated: true)
                    self.fetchingView.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } else {
                print(response.error?.localizedDescription ?? "Unknown Error!")
                self.tagsError = response.error?.localizedDescription ?? "Unknown Error!"
                self.tagsErrorResponse = []
                self.tags = []
                self.navigationItem.title = "Error"
                self.navigationItem.setRightBarButton(nil, animated: true)
                self.fetchingView.stopAnimating()
                self.fetchingView.removeFromSuperview()
                self.setupTableView()
                self.tableViewController.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
            self.searchController.searchBar.placeholder = "Search \(self.tags.count.description) \(self.tags.count == 1 ? "Tag" : "Tags")"
            
        }
    }
}

extension AllTagsVC: UITableViewDataSource {
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
        
        if self.filteredTags.isEmpty && self.tagsError.isEmpty && self.tagsErrorResponse.isEmpty && !self.refreshControl.isRefreshing {
            noTagsCell.selectionStyle = .none
            noTagsCell.textLabel?.text = "No Tags"
            noTagsCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
            noTagsCell.backgroundColor = tableView.backgroundColor
            return noTagsCell
        } else {
            if !self.tagsError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
                errorStringCell.textLabel?.text = tagsError
                return errorStringCell
            } else if !self.tagsErrorResponse.isEmpty {
                let error = tagsErrorResponse[indexPath.row]
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .red
                errorObjectCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBold)
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.smallSystemFontSize)
                errorObjectCell.detailTextLabel?.text = error.detail
                return errorObjectCell
            } else {                
                let tag = filteredTags[indexPath.row]
                tagCell.accessoryType = .disclosureIndicator
                tagCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
                tagCell.textLabel?.adjustsFontForContentSizeCategory = true
                tagCell.textLabel?.text = tag.id
                return tagCell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.tagsErrorResponse.isEmpty && self.tagsError.isEmpty && !self.filteredTags.isEmpty {
            let vc = TransactionsByTagVC()
            vc.tag = filteredTags[indexPath.row]
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if self.tagsErrorResponse.isEmpty && self.tagsError.isEmpty && !self.filteredTags.isEmpty {
            let tag = filteredTags[indexPath.row]
            
            let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = tag.id
            }
            
            return UIContextMenuConfiguration(identifier: nil,
                                              previewProvider: nil) { _ in
                UIMenu(title: "", children: [copy])
            }
        } else {
            return nil
        }
    }
}
