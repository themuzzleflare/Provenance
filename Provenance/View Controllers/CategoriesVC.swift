import UIKit
import Alamofire
import TinyConstraints
import Rswift

class CategoriesVC: ViewController {
    let fetchingView = ActivityIndicator(style: .medium)
    let tableViewController = TableViewController(style: .insetGrouped)
    let refreshControl = RefreshControl(frame: .zero)
    let searchController = UISearchController(searchResultsController: nil)
    
    private var categories: [CategoryResource] = []
    private var categoriesErrorResponse: [ErrorObject] = []
    private var categoriesError: String = ""
    private var prevFilteredCategories: [CategoryResource] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureProperties()
        configureNavigation()
        configureSearch()
        configureRefreshControl()
        configureFetchingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchCategories()
    }
}

extension CategoriesVC {
    private var filteredCategories: [CategoryResource] {
        categories.filter { category in
            searchController.searchBar.text!.isEmpty || category.attributes.name.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    
    @objc private func refreshCategories() {
        #if targetEnvironment(macCatalyst)
        let loadingView = ActivityIndicator(style: .medium)
        
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loadingView), animated: true)
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchCategories()
        }
    }
    
    private func configureProperties() {
        title = "Categories"
    }
    
    private func configureNavigation() {
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.arrowUpArrowDownCircle(), style: .plain, target: self, action: nil)
        
        #if targetEnvironment(macCatalyst)
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshCategories)), animated: true)
        #endif
    }
    
    private func configureSearch() {
        searchController.delegate = self
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        
        searchController.searchBar.delegate = self
        
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
        
        definesPresentationContext = true
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func configureRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshCategories), for: .valueChanged)
        
        tableViewController.refreshControl = refreshControl
    }
    
    private func configureFetchingView() {
        view.addSubview(fetchingView)
        
        fetchingView.edgesToSuperview()
    }
    
    private func configureTableView() {
        super.addChild(tableViewController)
        
        view.addSubview(tableViewController.tableView)
        
        tableViewController.tableView.edgesToSuperview()
        
        tableViewController.tableView.delegate = self
        tableViewController.tableView.dataSource = self
        
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "categoryCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noCategoriesCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    private func fetchCategories() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        
        AF.request(UpApi.Categories().listCategories, method: .get, headers: headers).responseJSON { response in
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Category.self, from: response.data!) {
                        print("Categories JSON decoding succeeded")
                        
                        self.categories = decodedResponse.data
                        self.categoriesError = ""
                        self.categoriesErrorResponse = []
                        
                        if self.navigationItem.title != "Categories" {
                            self.navigationItem.title = "Categories"
                        }
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshCategories)), animated: true)
                        #endif
                        
                        if self.fetchingView.isDescendant(of: self.view) {
                            self.fetchingView.removeFromSuperview()
                        }
                        if !self.tableViewController.tableView.isDescendant(of: self.view) {
                            self.configureTableView()
                        }
                        
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                        
                        if self.searchController.isActive {
                            self.prevFilteredCategories = self.filteredCategories
                        }
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        print("Categories Error JSON decoding succeeded")
                        
                        self.categoriesErrorResponse = decodedResponse.errors
                        self.categoriesError = ""
                        self.categories = []
                        
                        if self.navigationItem.title != "Errors" {
                            self.navigationItem.title = "Errors"
                        }
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshCategories)), animated: true)
                        #endif
                        
                        if self.fetchingView.isDescendant(of: self.view) {
                            self.fetchingView.removeFromSuperview()
                        }
                        if !self.tableViewController.tableView.isDescendant(of: self.view) {
                            self.configureTableView()
                        }
                        
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    } else {
                        print("Categories JSON decoding failed")
                        
                        self.categoriesError = "JSON Decoding Failed!"
                        self.categoriesErrorResponse = []
                        self.categories = []
                        
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshCategories)), animated: true)
                        #endif
                        
                        if self.fetchingView.isDescendant(of: self.view) {
                            self.fetchingView.removeFromSuperview()
                        }
                        if !self.tableViewController.tableView.isDescendant(of: self.view) {
                            self.configureTableView()
                        }
                        
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
                    
                    self.categoriesError = response.error?.localizedDescription ?? "Unknown Error!"
                    self.categoriesErrorResponse = []
                    self.categories = []
                    
                    if self.navigationItem.title != "Error" {
                        self.navigationItem.title = "Error"
                    }
                    
                    #if targetEnvironment(macCatalyst)
                    self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshCategories)), animated: true)
                    #endif
                    
                    if self.fetchingView.isDescendant(of: self.view) {
                        self.fetchingView.removeFromSuperview()
                    }
                    if !self.tableViewController.tableView.isDescendant(of: self.view) {
                        self.configureTableView()
                    }
                    
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
            }
            self.searchController.searchBar.placeholder = "Search \(self.categories.count.description) \(self.categories.count == 1 ? "Category" : "Categories")"
        }
    }
}

extension CategoriesVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredCategories.isEmpty && categoriesError.isEmpty && categoriesErrorResponse.isEmpty {
            return 1
        } else {
            if !categoriesError.isEmpty {
                return 1
            } else if !categoriesErrorResponse.isEmpty {
                return categoriesErrorResponse.count
            } else {
                return filteredCategories.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let categoryCell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        let noCategoriesCell = tableView.dequeueReusableCell(withIdentifier: "noCategoriesCell", for: indexPath)
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if filteredCategories.isEmpty && categoriesError.isEmpty && categoriesErrorResponse.isEmpty {
            tableView.separatorStyle = .none
            
            noCategoriesCell.selectionStyle = .none
            noCategoriesCell.textLabel?.font = circularStdBook
            noCategoriesCell.textLabel?.textColor = .white
            noCategoriesCell.textLabel?.textAlignment = .center
            noCategoriesCell.textLabel?.text = "No Categories"
            noCategoriesCell.backgroundColor = .clear
            
            return noCategoriesCell
        } else {
            tableView.separatorStyle = .singleLine
            
            if !categoriesError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.font = circularStdBook
                errorStringCell.textLabel?.text = categoriesError
                
                return errorStringCell
            } else if !categoriesErrorResponse.isEmpty {
                let error = categoriesErrorResponse[indexPath.row]
                
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .systemRed
                errorObjectCell.textLabel?.font = circularStdBold
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
                errorObjectCell.detailTextLabel?.text = error.detail
                
                return errorObjectCell
            } else {
                let category = filteredCategories[indexPath.row]
                
                categoryCell.selectedBackgroundView = bgCellView
                categoryCell.accessoryType = .none
                categoryCell.textLabel?.font = circularStdBook
                categoryCell.textLabel?.text = category.attributes.name
                
                return categoryCell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if categoriesErrorResponse.isEmpty && categoriesError.isEmpty && !filteredCategories.isEmpty {
            let vc = TransactionsByCategoryVC()
            
            vc.category = filteredCategories[indexPath.row]
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if categoriesErrorResponse.isEmpty && categoriesError.isEmpty && !filteredCategories.isEmpty {
            let copy = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                UIPasteboard.general.string = self.filteredCategories[indexPath.row].attributes.name
            }
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                UIMenu(children: [copy])
            }
        } else {
            return nil
        }
    }
}

extension CategoriesVC: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if prevFilteredCategories != filteredCategories {
            prevFilteredCategories = filteredCategories
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if filteredCategories != prevFilteredCategories {
            tableViewController.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
        prevFilteredCategories = filteredCategories
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searchBar.text = ""
            prevFilteredCategories = filteredCategories
            tableViewController.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
}
