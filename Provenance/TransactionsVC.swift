import UIKit

class TransactionsVC: UIViewController, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    let fetchingView: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    let tableViewController: UITableViewController = UITableViewController(style: .grouped)
    
    let circularStdBook = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)!
    let circularStdBold = UIFont(name: "CircularStd-Bold", size: UIFont.labelFontSize)!
    
    lazy var refreshControl: UIRefreshControl = UIRefreshControl()
    lazy var searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    lazy var transactions: [TransactionResource] = []
    lazy var transactionsErrorResponse: [ErrorObject] = []
    lazy var transactionsError: String = ""
    lazy var filteredTransactions: [TransactionResource] = []
    
    lazy var categories: [CategoryResource] = []
    
    lazy var accounts: [AccountResource] = []
    
    lazy var showSettledOnly: Bool = false
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredTransactions = transactions.filter { (!showSettledOnly || $0.attributes.isSettled) &&
            (searchController.searchBar.text!.isEmpty || $0.attributes.description.localizedStandardContains(searchController.searchBar.text!)) }
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
        
        title = "Transactions"
        navigationItem.title = "Loading"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        tableViewController.clearsSelectionOnViewWillAppear = true
        tableViewController.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
        
        setupFetchingView()
    }
    
    @objc private func switchDateStyle() {
        if UserDefaults.standard.string(forKey: "dateStyle") == "Absolute" || UserDefaults.standard.string(forKey: "dateStyle") == nil {
            UserDefaults.standard.setValue("Relative", forKey: "dateStyle")
        } else if UserDefaults.standard.string(forKey: "dateStyle") == "Relative" {
            UserDefaults.standard.setValue("Absolute", forKey: "dateStyle")
        }
        tableViewController.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        filteredTransactions = transactions.filter { (!showSettledOnly || $0.attributes.isSettled) &&
            (searchController.searchBar.text!.isEmpty || $0.attributes.description.localizedStandardContains(searchController.searchBar.text!)) }
        tableViewController.tableView.reloadData()
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
        
        tableViewController.tableView.register(UINib(nibName: "SettledOnlyCell", bundle: nil), forCellReuseIdentifier: "settledOnlyCell")
        tableViewController.tableView.register(UINib(nibName: "TransactionCell", bundle: nil), forCellReuseIdentifier: "transactionCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noTransactionsCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    private func listTransactions() {
        var url = URL(string: "https://api.up.com.au/api/v1/transactions")!
        let urlParams = ["page[size]":"100"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Transactions JSON Decoding Succeeded!")
                        self.transactions = decodedResponse.data
                        self.transactionsError = ""
                        self.filteredTransactions = self.transactions.filter { (!self.showSettledOnly || $0.attributes.isSettled) &&
                            (self.searchController.searchBar.text!.isEmpty || $0.attributes.description.localizedStandardContains(self.searchController.searchBar.text!)) }
                        self.transactionsErrorResponse = []
                        self.navigationItem.title = "Transactions"
                        self.navigationItem.setLeftBarButton(UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(self.switchDateStyle)), animated: true)
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Transactions Error JSON Decoding Succeeded!")
                        self.transactionsErrorResponse = decodedResponse.errors
                        self.transactionsError = ""
                        self.transactions = []
                        self.navigationItem.title = "Errors"
                        self.navigationItem.setLeftBarButton(nil, animated: true)
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Transactions JSON Decoding Failed!")
                        self.transactionsError = "JSON Decoding Failed!"
                        self.transactionsErrorResponse = []
                        self.transactions = []
                        self.navigationItem.title = "Error"
                        self.navigationItem.setLeftBarButton(nil, animated: true)
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
                    self.transactionsError = error?.localizedDescription ?? "Unknown Error!"
                    self.transactionsErrorResponse = []
                    self.transactions = []
                    self.navigationItem.title = "Error"
                    self.navigationItem.setLeftBarButton(nil, animated: true)
                    self.fetchingView.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
            DispatchQueue.main.async {
                self.searchController.searchBar.placeholder = "Search \(self.transactions.filter { (!self.showSettledOnly || $0.attributes.isSettled)}.count.description) \(self.transactions.filter { (!self.showSettledOnly || $0.attributes.isSettled)}.count == 1 ? "Transaction" : "Transactions")"
            }
        }
        .resume()
    }
}

extension TransactionsVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.filteredTransactions.isEmpty && self.transactionsError.isEmpty && self.transactionsErrorResponse.isEmpty {
            return 1
        } else {
            if !self.transactionsError.isEmpty {
                return 1
            } else if !self.transactionsErrorResponse.isEmpty {
                if section == 0 {
                    return 1
                } else {
                    return transactionsErrorResponse.count
                }
            } else {
                if section == 0 {
                    return 1
                } else {
                    return filteredTransactions.count
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        
        let settledOnlyCell = tableView.dequeueReusableCell(withIdentifier: "settledOnlyCell", for: indexPath) as! SettledOnlyCell
        
        let transactionCell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath) as! TransactionCell
        
        let noTransactionsCell = tableView.dequeueReusableCell(withIdentifier: "noTransactionsCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.showSettledOnly {
            settledOnlyCell.rightSwitch.setOn(true, animated: true)
            settledOnlyCell.checkmarkCircle.tintColor = .systemGreen
            settledOnlyCell.leftLabel.textColor = .label
        } else {
            settledOnlyCell.rightSwitch.setOn(false, animated: true)
            settledOnlyCell.checkmarkCircle.tintColor = .secondaryLabel
            settledOnlyCell.leftLabel.textColor = .secondaryLabel
        }
        settledOnlyCell.rightSwitch.addTarget(self, action: #selector(switchSettledOnly), for: .valueChanged)
        
        if self.filteredTransactions.isEmpty && self.transactionsError.isEmpty && self.transactionsErrorResponse.isEmpty && !self.refreshControl.isRefreshing {
            if section == 0 {
                return settledOnlyCell
            } else {
                noTransactionsCell.selectionStyle = .none
                noTransactionsCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
                noTransactionsCell.textLabel?.text = "No Transactions"
                noTransactionsCell.backgroundColor = tableView.backgroundColor
                return noTransactionsCell
            }
        } else {
            if !self.transactionsError.isEmpty {
                if section == 0 {
                    return settledOnlyCell
                } else {
                    errorStringCell.selectionStyle = .none
                    errorStringCell.textLabel?.numberOfLines = 0
                    errorStringCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
                    errorStringCell.textLabel?.text = transactionsError
                    return errorStringCell
                }
            } else if !self.transactionsErrorResponse.isEmpty {
                if section == 0 {
                    return settledOnlyCell
                } else {
                    let error = transactionsErrorResponse[indexPath.row]
                    errorObjectCell.selectionStyle = .none
                    errorObjectCell.textLabel?.textColor = .red
                    errorObjectCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBold)
                    errorObjectCell.textLabel?.text = error.title
                    errorObjectCell.detailTextLabel?.numberOfLines = 0
                    errorObjectCell.detailTextLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.smallSystemFontSize)
                    errorObjectCell.detailTextLabel?.text = error.detail
                    return errorObjectCell
                }
            } else {
                if section == 0 {
                    return settledOnlyCell
                } else {
                    let transaction = filteredTransactions[indexPath.row]
                    
                    var createdDate: String {
                        switch UserDefaults.standard.string(forKey: "dateStyle") {
                            case "Absolute", .none: return transaction.attributes.createdDate
                            case "Relative": return transaction.attributes.createdDateRelative
                            default: return transaction.attributes.createdDate
                        }
                    }
                    
                    transactionCell.leftLabel.text = transaction.attributes.description
                    transactionCell.leftSubtitle.text = createdDate
                    transactionCell.rightLabel.text = "\(transaction.attributes.amount.valueSymbol)\(transaction.attributes.amount.valueString)"
                    return transactionCell
                }
            }
        }
    }
    
    @objc private func switchSettledOnly(toggle: UISwitch) {
        if toggle.isOn {
            self.showSettledOnly = true
        } else {
            self.showSettledOnly = false
        }
        self.filteredTransactions = self.transactions.filter { (!self.showSettledOnly || $0.attributes.isSettled) &&
            (self.searchController.searchBar.text!.isEmpty || $0.attributes.description.localizedStandardContains(self.searchController.searchBar.text!)) }
        self.searchController.searchBar.placeholder = "Search \(self.transactions.filter { (!self.showSettledOnly || $0.attributes.isSettled)}.count.description) \(self.transactions.filter { (!self.showSettledOnly || $0.attributes.isSettled)}.count == 1 ? "Transaction" : "Transactions")"
        tableViewController.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.transactionsErrorResponse.isEmpty && self.transactionsError.isEmpty && !self.filteredTransactions.isEmpty {
            let section = indexPath.section
            
            if section == 1 {
                let vc = TransactionDetailVC(style: .grouped)
                vc.transaction = filteredTransactions[indexPath.row]
                vc.categories = self.categories
                vc.accounts = self.accounts
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if self.transactionsErrorResponse.isEmpty && self.transactionsError.isEmpty && !self.filteredTransactions.isEmpty {
            let section = indexPath.section
            
            if section == 1 {
                let transaction = filteredTransactions[indexPath.row]
                
                let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = transaction.attributes.description
                }
                
                return UIContextMenuConfiguration(identifier: nil,
                                                  previewProvider: nil) { _ in
                    UIMenu(title: "", children: [copy])
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
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
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Categories JSON Decoding Failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print(error?.localizedDescription ?? "Unknown Error!")
                }
            }
        }
        .resume()
    }
    
    private func listAccounts() {
        let url = URL(string: "https://api.up.com.au/api/v1/accounts")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Account.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Accounts JSON Decoding Succeeded!")
                        self.accounts = decodedResponse.data
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Accounts JSON Decoding Failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print(error?.localizedDescription ?? "Unknown Error!")
                }
            }
        }
        .resume()
    }
}
