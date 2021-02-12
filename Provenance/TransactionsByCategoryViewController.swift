import UIKit
import Alamofire

class TransactionsByCategoryViewController: UIViewController, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    var category: CategoryResource!
    
    let fetchingView = UIActivityIndicatorView(style: .medium)
    let tableViewController = UITableViewController(style: .grouped)
    lazy var refreshControl: UIRefreshControl = UIRefreshControl()
    lazy var searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    var transactions = [TransactionResource]()
    var transactionsErrorResponse = [ErrorObject]()
    var transactionsError: String = ""
    lazy var filteredTransactions: [TransactionResource] = []
    
    var categories = [CategoryResource]()
    var categoriesErrorResponse = [ErrorObject]()
    var categoriesError: String = ""
    
    var accounts = [AccountResource]()
    var accountsErrorResponse = [ErrorObject]()
    var accountsError: String = ""
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredTransactions = transactions.filter { searchController.searchBar.text!.isEmpty || $0.attributes.description.localizedStandardContains(searchController.searchBar.text!) }
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
        
        self.title = "Transactions by Category"
        
        navigationItem.title = "Loading"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        tableViewController.clearsSelectionOnViewWillAppear = true
        tableViewController.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
        
        setupFetchingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        listTransactions()
        listCategories()
        listAccounts()
    }
    
    @objc private func refreshTransactions() {
        listTransactions()
        listCategories()
        listAccounts()
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
        
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "transactionCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "fetchingCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    func listTransactions() {
        let urlString = "https://api.up.com.au/api/v1/transactions"
        let parameters: Parameters = ["filter[category]":category.id, "page[size]":"100"]
        let headers: HTTPHeaders = [
            "Accept": "application/json",
            "Authorization": "Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")"
        ]
        AF.request(urlString, method: .get, parameters: parameters, headers: headers).responseJSON { response in
            self.fetchingView.stopAnimating()
            self.fetchingView.removeFromSuperview()
            self.setupTableView()
            if response.error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: response.data!) {
                    print("Transactions JSON Decoding Succeeded!")
                    self.transactions = decodedResponse.data
                    self.filteredTransactions = self.transactions.filter { self.searchController.searchBar.text!.isEmpty || $0.attributes.description.localizedStandardContains(self.searchController.searchBar.text!) }
                    self.transactionsError = ""
                    self.transactionsErrorResponse = []
                    self.navigationItem.title = self.category.attributes.name
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                    print("Transactions Error JSON Decoding Succeeded!")
                    self.transactionsErrorResponse = decodedResponse.errors
                    self.transactionsError = ""
                    self.transactions = []
                    self.navigationItem.title = "Errors"
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                } else {
                    print("Transactions JSON Decoding Failed!")
                    self.transactionsError = "JSON Decoding Failed!"
                    self.transactionsErrorResponse = []
                    self.transactions = []
                    self.navigationItem.title = "Error"
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } else {
                print(response.error?.localizedDescription ?? "Unknown Error!")
                self.transactionsError = response.error?.localizedDescription ?? "Unknown Error!"
                self.transactionsErrorResponse = []
                self.transactions = []
                self.navigationItem.title = "Error"
                self.tableViewController.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
}

extension TransactionsByCategoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.filteredTransactions.isEmpty && self.transactionsError.isEmpty && self.transactionsErrorResponse.isEmpty {
            return 1
        } else {
            if !self.transactionsError.isEmpty {
                return 1
            } else if !self.transactionsErrorResponse.isEmpty {
                return transactionsErrorResponse.count
            } else {
                return filteredTransactions.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let transactionCell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath) as! SubtitleTableViewCell
        
        let fetchingCell = tableView.dequeueReusableCell(withIdentifier: "fetchingCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.filteredTransactions.isEmpty && self.transactionsError.isEmpty && self.transactionsErrorResponse.isEmpty && !self.refreshControl.isRefreshing {
            fetchingCell.selectionStyle = .none
            fetchingCell.textLabel?.text = "No Transactions"
            fetchingCell.backgroundColor = tableView.backgroundColor
            return fetchingCell
        } else {
            if !self.transactionsError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.text = transactionsError
                return errorStringCell
            } else if !self.transactionsErrorResponse.isEmpty {
                let error = transactionsErrorResponse[indexPath.row]
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .red
                errorObjectCell.textLabel?.font = .boldSystemFont(ofSize: 17)
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.text = error.detail
                return errorObjectCell
            } else {
                let transaction = filteredTransactions[indexPath.row]
                transactionCell.accessoryType = .disclosureIndicator
                transactionCell.textLabel?.font = .boldSystemFont(ofSize: 17)
                transactionCell.textLabel?.textColor = .label
                transactionCell.textLabel?.text = transaction.attributes.description
                transactionCell.detailTextLabel?.textColor = .secondaryLabel
                transactionCell.detailTextLabel?.text =
                    "\(transaction.attributes.amount.valueSymbol)\(transaction.attributes.amount.valueString)"
                return transactionCell
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.transactionsErrorResponse.isEmpty && self.transactionsError.isEmpty && !self.filteredTransactions.isEmpty {
            let vc = TransactionDetailViewController(style: .grouped)
            vc.transaction = filteredTransactions[indexPath.row]
            vc.categories = self.categories
            vc.accounts = self.accounts
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func listCategories() {
        let urlString = "https://api.up.com.au/api/v1/categories"
        let headers: HTTPHeaders = [
            "Accept": "application/json",
            "Authorization": "Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")"
        ]
        AF.request(urlString, method: .get, headers: headers).responseJSON { response in
            if response.error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Category.self, from: response.data!) {
                    print("Categories JSON Decoding Succeeded!")
                    self.categories = decodedResponse.data
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                    print("Categories Error JSON Decoding Succeeded!")
                    self.categoriesErrorResponse = decodedResponse.errors
                } else {
                    print("Categories JSON Decoding Failed!")
                    self.categoriesError = "JSON Decoding Failed!"
                }
            } else {
                print(response.error?.localizedDescription ?? "Unknown Error!")
                self.categoriesError = response.error?.localizedDescription ?? "Unknown Error!"
            }
        }
    }
    
    func listAccounts() {
        let urlString = "https://api.up.com.au/api/v1/accounts"
        let headers: HTTPHeaders = [
            "Accept": "application/json",
            "Authorization": "Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")"
        ]
        AF.request(urlString, method: .get, headers: headers).responseJSON { response in
            if response.error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Account.self, from: response.data!) {
                    print("Accounts JSON Decoding Succeeded!")
                    self.accounts = decodedResponse.data
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                    print("Accounts Error JSON Decoding Succeeded!")
                    self.accountsErrorResponse = decodedResponse.errors
                } else {
                    print("Accounts JSON Decoding Failed!")
                    self.accountsError = "JSON Decoding Failed!"
                }
            } else {
                print(response.error?.localizedDescription ?? "Unknown Error!")
                self.accountsError = response.error?.localizedDescription ?? "Unknown Error!"
            }
        }
    }
}
