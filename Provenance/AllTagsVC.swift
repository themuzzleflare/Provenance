import UIKit
import Rswift

class AllTagsVC: ViewController, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate {
    let fetchingView = ActivityIndicator(style: .medium)
    let tableViewController = TableViewController(style: .insetGrouped)
    
    let circularStdBook = R.font.circularStdBook(size: UIFont.labelFontSize)
    let circularStdBold = R.font.circularStdBold(size: UIFont.labelFontSize)
    
    let refreshControl = RefreshControl(frame: .zero)
    lazy var searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    lazy var tags: [TagResource] = []
    lazy var tagsErrorResponse: [ErrorObject] = []
    lazy var tagsError: String = ""
    
    private var prevFilteredTags: [TagResource] = []
    private var filteredTags: [TagResource] {
        tags.filter { tag in
            searchController.searchBar.text!.isEmpty || tag.id.localizedStandardContains(searchController.searchBar.text!)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.addChild(tableViewController)
                
        self.searchController.delegate = self
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.searchBarStyle = .minimal
        self.searchController.searchBar.placeholder = "Search"
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.searchController.searchBar.delegate = self
        
        self.definesPresentationContext = true
        
        self.title = "Tags"
        self.navigationItem.searchController = searchController
        self.navigationItem.title = "Loading"
        self.navigationItem.hidesSearchBarWhenScrolling = false
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        #if targetEnvironment(macCatalyst)
        self.navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTags)), animated: true)
        #endif
        
        self.tableViewController.clearsSelectionOnViewWillAppear = true
        self.tableViewController.refreshControl = refreshControl
        self.refreshControl.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
        
        self.setupFetchingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.listTags()
    }
    
    @objc private func openAddWorkflow() {
        let vc = NavigationController(rootViewController: AddTagWorkflowVC())
        present(vc, animated: true)
    }
    
    @objc private func refreshTags() {
        #if targetEnvironment(macCatalyst)
        let loadingView = ActivityIndicator()
        navigationItem.setLeftBarButton(UIBarButtonItem(customView: loadingView), animated: true)
        #endif
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.listTags()
        }
    }
    
    func setupFetchingView() {
        view.addSubview(fetchingView)
        
        fetchingView.translatesAutoresizingMaskIntoConstraints = false
        fetchingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        fetchingView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        fetchingView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        fetchingView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
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
    
    private func listTags() {
        var url = URL(string: "https://api.up.com.au/api/v1/tags")!
        let urlParams = ["page[size]":"200"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Tag.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Tags JSON Decoding Succeeded!")
                        self.tags = decodedResponse.data
                        self.tagsError = ""
                        self.tagsErrorResponse = []
                        self.navigationItem.title = "Tags"
                        if self.navigationItem.rightBarButtonItem == nil {
                            self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.openAddWorkflow)), animated: true)
                        }
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTags)), animated: true)
                        #endif
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Tags Error JSON Decoding Succeeded!")
                        self.tagsErrorResponse = decodedResponse.errors
                        self.tagsError = ""
                        self.tags = []
                        self.navigationItem.title = "Errors"
                        self.navigationItem.setRightBarButton(nil, animated: true)
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTags)), animated: true)
                        #endif
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Tags JSON Decoding Failed!")
                        self.tagsError = "JSON Decoding Failed!"
                        self.tagsErrorResponse = []
                        self.tags = []
                        self.navigationItem.title = "Error"
                        self.navigationItem.setRightBarButton(nil, animated: true)
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTags)), animated: true)
                        #endif
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print(error?.localizedDescription ?? "Unknown Error!")
                    self.tagsError = error?.localizedDescription ?? "Unknown Error!"
                    self.tagsErrorResponse = []
                    self.tags = []
                    self.navigationItem.title = "Error"
                    self.navigationItem.setRightBarButton(nil, animated: true)
                    #if targetEnvironment(macCatalyst)
                    self.navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTags)), animated: true)
                    #endif
                    self.fetchingView.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
            DispatchQueue.main.async {
                self.searchController.searchBar.placeholder = "Search \(self.tags.count.description) \(self.tags.count == 1 ? "Tag" : "Tags")"
            }
        }
        .resume()
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
                tagCell.accessoryType = .disclosureIndicator
                tagCell.textLabel?.font = circularStdBook
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
