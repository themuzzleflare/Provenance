import UIKit
import Alamofire

class CategoriesViewController: UIViewController, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    let fetchingView = UIActivityIndicatorView(style: .medium)
    let tableViewController = UITableViewController(style: .grouped)
    lazy var refreshControl: UIRefreshControl = UIRefreshControl()
    lazy var searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    var categories = [CategoryResource]()
    var categoriesErrorResponse = [ErrorObject]()
    var categoriesError: String = ""
    lazy var filteredCategories: [CategoryResource] = []
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredCategories = categories.filter { searchController.searchBar.text!.isEmpty || $0.attributes.name.localizedStandardContains(searchController.searchBar.text!) }
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
        
        self.title = "Categories"
        
        navigationItem.title = "Loading"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        tableViewController.clearsSelectionOnViewWillAppear = true
        tableViewController.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshCategories), for: .valueChanged)
        
        setupFetchingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        listCategories()
    }
    
    @objc private func refreshCategories() {
        listCategories()
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
        
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "categoryCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "fetchingCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    func listCategories() {
        let urlString = "https://api.up.com.au/api/v1/categories"
        let headers: HTTPHeaders = [
            "Accept": "application/json",
            "Authorization": "Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")"
        ]
        AF.request(urlString, method: .get, headers: headers).responseJSON { response in
            self.fetchingView.stopAnimating()
            self.fetchingView.removeFromSuperview()
            self.setupTableView()
            if response.error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Category.self, from: response.data!) {
                    print("Categories JSON Decoding Succeeded!")
                    self.categories = decodedResponse.data
                    self.filteredCategories = self.categories.filter { self.searchController.searchBar.text!.isEmpty || $0.attributes.name.localizedStandardContains(self.searchController.searchBar.text!) }
                    self.categoriesError = ""
                    self.categoriesErrorResponse = []
                    self.navigationItem.title = "Categories"
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                    print("Categories Error JSON Decoding Succeeded!")
                    self.categoriesErrorResponse = decodedResponse.errors
                    self.categoriesError = ""
                    self.categories = []
                    self.navigationItem.title = "Errors"
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                } else {
                    print("Categories JSON Decoding Failed!")
                    self.categoriesError = "JSON Decoding Failed!"
                    self.categoriesErrorResponse = []
                    self.categories = []
                    self.navigationItem.title = "Error"
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } else {
                print(response.error?.localizedDescription ?? "Unknown Error!")
                self.categoriesError = response.error?.localizedDescription ?? "Unknown Error!"
                self.categoriesErrorResponse = []
                self.categories = []
                self.navigationItem.title = "Error"
                self.tableViewController.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
}

extension CategoriesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.filteredCategories.isEmpty && self.categoriesError.isEmpty && self.categoriesErrorResponse.isEmpty {
            return 1
        } else {
            if !self.categoriesError.isEmpty {
                return 1
            } else if !self.categoriesErrorResponse.isEmpty {
                return categoriesErrorResponse.count
            } else {
                return filteredCategories.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let categoryCell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        
        let fetchingCell = tableView.dequeueReusableCell(withIdentifier: "fetchingCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.filteredCategories.isEmpty && self.categoriesError.isEmpty && self.categoriesErrorResponse.isEmpty && !self.refreshControl.isRefreshing {
            fetchingCell.selectionStyle = .none
            fetchingCell.textLabel?.text = "No Categories"
            fetchingCell.backgroundColor = tableView.backgroundColor
            return fetchingCell
        } else {
            if !self.categoriesError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.text = categoriesError
                return errorStringCell
            } else if !self.categoriesErrorResponse.isEmpty {
                let error = categoriesErrorResponse[indexPath.row]
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .red
                errorObjectCell.textLabel?.font = .boldSystemFont(ofSize: 17)
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.text = error.detail
                return errorObjectCell
            } else {
                let category = filteredCategories[indexPath.row]
                categoryCell.accessoryType = .disclosureIndicator
                categoryCell.textLabel?.text = category.attributes.name
                return categoryCell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.categoriesErrorResponse.isEmpty && self.categoriesError.isEmpty && !self.filteredCategories.isEmpty {
            let vc = TransactionsByCategoryViewController()
            vc.category = filteredCategories[indexPath.row]
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
