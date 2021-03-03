import UIKit

class CategoriesVC: UIViewController, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    let fetchingView: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    let tableViewController: UITableViewController = UITableViewController(style: .grouped)
    
    let circularStdBook = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)!
    let circularStdBold = UIFont(name: "CircularStd-Bold", size: UIFont.labelFontSize)!
    
    lazy var refreshControl: UIRefreshControl = UIRefreshControl()
    lazy var searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    lazy var categories: [CategoryResource] = []
    lazy var categoriesErrorResponse: [ErrorObject] = []
    lazy var categoriesError: String = ""
    
    private var filteredCategories: [CategoryResource] {
        categories.filter { category in
            searchController.searchBar.text!.isEmpty || category.attributes.name.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
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
        
        title = "Categories"
        navigationItem.title = "Loading"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        #if targetEnvironment(macCatalyst)
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshCategories)), animated: true)
        #endif
        
        tableViewController.clearsSelectionOnViewWillAppear = true
        tableViewController.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshCategories), for: .valueChanged)
        
        setupFetchingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        listCategories()
    }
    
    @objc private func refreshCategories() {
        #if targetEnvironment(macCatalyst)
        let loadingView = UIActivityIndicatorView(style: .medium)
        loadingView.startAnimating()
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loadingView), animated: true)
        #endif
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.listCategories()
        }
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
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noCategoriesCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    private func listCategories() {
        let url = URL(string: "https://api.up.com.au/api/v1/categories")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Category.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Categories JSON Decoding Succeeded!")
                        self.categories = decodedResponse.data
                        self.categoriesError = ""
                        self.categoriesErrorResponse = []
                        self.navigationItem.title = "Categories"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshCategories)), animated: true)
                        #endif
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Categories Error JSON Decoding Succeeded!")
                        self.categoriesErrorResponse = decodedResponse.errors
                        self.categoriesError = ""
                        self.categories = []
                        self.navigationItem.title = "Errors"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshCategories)), animated: true)
                        #endif
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Categories JSON Decoding Failed!")
                        self.categoriesError = "JSON Decoding Failed!"
                        self.categoriesErrorResponse = []
                        self.categories = []
                        self.navigationItem.title = "Error"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshCategories)), animated: true)
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
                    self.categoriesError = error?.localizedDescription ?? "Unknown Error!"
                    self.categoriesErrorResponse = []
                    self.categories = []
                    self.navigationItem.title = "Error"
                    #if targetEnvironment(macCatalyst)
                    self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshCategories)), animated: true)
                    #endif
                    self.fetchingView.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
            DispatchQueue.main.async {
                self.searchController.searchBar.placeholder = "Search \(self.categories.count.description) \(self.categories.count == 1 ? "Category" : "Categories")"
            }
        }
        .resume()
    }
}

extension CategoriesVC: UITableViewDataSource {
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
        
        let noCategoriesCell = tableView.dequeueReusableCell(withIdentifier: "noCategoriesCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.filteredCategories.isEmpty && self.categoriesError.isEmpty && self.categoriesErrorResponse.isEmpty && !self.refreshControl.isRefreshing {
            tableView.separatorStyle = .none
            noCategoriesCell.selectionStyle = .none
            noCategoriesCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
            noCategoriesCell.textLabel?.textAlignment = .center
            noCategoriesCell.textLabel?.text = "No Categories"
            noCategoriesCell.backgroundColor = tableView.backgroundColor
            return noCategoriesCell
        } else {
            tableView.separatorStyle = .singleLine
            if !self.categoriesError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
                errorStringCell.textLabel?.text = categoriesError
                return errorStringCell
            } else if !self.categoriesErrorResponse.isEmpty {
                let error = categoriesErrorResponse[indexPath.row]
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .red
                errorObjectCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBold)
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.smallSystemFontSize)
                errorObjectCell.detailTextLabel?.text = error.detail
                return errorObjectCell
            } else {
                let category = filteredCategories[indexPath.row]
                categoryCell.accessoryType = .disclosureIndicator
                categoryCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
                categoryCell.textLabel?.text = category.attributes.name
                return categoryCell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.categoriesErrorResponse.isEmpty && self.categoriesError.isEmpty && !self.filteredCategories.isEmpty {
            let vc = TransactionsByCategoryVC()
            vc.category = filteredCategories[indexPath.row]
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if self.categoriesErrorResponse.isEmpty && self.categoriesError.isEmpty && !self.filteredCategories.isEmpty {
            let category = filteredCategories[indexPath.row]
            
            let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = category.attributes.name
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
