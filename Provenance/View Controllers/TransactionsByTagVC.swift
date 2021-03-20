import UIKit
import TinyConstraints
import Rswift

class TransactionsByTagVC: ViewController {
    var tag: TagResource!
    
    let fetchingView = ActivityIndicator(style: .medium)
    let tableViewController = TableViewController(style: .insetGrouped)
    let refreshControl = RefreshControl(frame: .zero)
    let searchController = UISearchController(searchResultsController: nil)
    
    private var categories: [CategoryResource] = []
    private var accounts: [AccountResource] = []
    private var prevFilteredTransactions: [TransactionResource] = []
    private var transactions: [TransactionResource] = []
    private var transactionsErrorResponse: [ErrorObject] = []
    private var transactionsError: String = ""
    private var filteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
            searchController.searchBar.text!.isEmpty || transaction.attributes.description.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    
    @objc private func refreshTransactions() {
        #if targetEnvironment(macCatalyst)
        let loadingView = ActivityIndicator(style: .medium)
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loadingView), animated: true)
        #endif
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.listTransactions()
            self.listCategories()
            self.listAccounts()
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
        tableViewController.tableView.reloadData()
        
        listTransactions()
        listCategories()
        listAccounts()
    }
    
    private func setProperties() {
        title = "Transactions by Tag"
    }
    
    private func setupNavigation() {
        navigationItem.title = "Loading"
        navigationItem.largeTitleDisplayMode = .never
        #if targetEnvironment(macCatalyst)
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTransactions)), animated: true)
        #endif
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
        refreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
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
        
        tableViewController.tableView.register(R.nib.transactionCell)
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noTransactionsCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    private func listTransactions() {
        var url = URL(string: "https://api.up.com.au/api/v1/transactions")!
        let urlParams = ["filter[tag]":tag.id, "page[size]":"100"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(appDefaults.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Transactions JSON decoding succeeded")
                        self.transactions = decodedResponse.data
                        self.transactionsError = ""
                        self.transactionsErrorResponse = []
                        self.navigationItem.title = self.tag.id
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Transactions Error JSON decoding succeeded")
                        self.transactionsErrorResponse = decodedResponse.errors
                        self.transactionsError = ""
                        self.transactions = []
                        self.navigationItem.title = "Errors"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Transactions JSON decoding failed")
                        self.transactionsError = "JSON Decoding Failed!"
                        self.transactionsErrorResponse = []
                        self.transactions = []
                        self.navigationItem.title = "Error"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print(error?.localizedDescription ?? "Unknown error")
                    self.transactionsError = error?.localizedDescription ?? "Unknown Error!"
                    self.transactionsErrorResponse = []
                    self.transactions = []
                    self.navigationItem.title = "Error"
                    #if targetEnvironment(macCatalyst)
                    self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                    #endif
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
            DispatchQueue.main.async {
                self.searchController.searchBar.placeholder = "Search \(self.transactions.count.description) \(self.transactions.count == 1 ? "Transaction" : "Transactions")"
            }
        }
        .resume()
    }
    
    private func listCategories() {
        let url = URL(string: "https://api.up.com.au/api/v1/categories")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(appDefaults.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Category.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Categories JSON decoding succeeded")
                        self.categories = decodedResponse.data
                    }
                } else {
                    print("Categories JSON decoding failed")
                }
            } else {
                print(error?.localizedDescription ?? "Unknown error")
            }
        }
        .resume()
    }
    
    private func listAccounts() {
        let url = URL(string: "https://api.up.com.au/api/v1/accounts")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(appDefaults.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Account.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Accounts JSON decoding succeeded")
                        self.accounts = decodedResponse.data
                    }
                } else {
                    print("Accounts JSON decoding failed")
                }
            } else {
                print(error?.localizedDescription ?? "Unknown error")
            }
        }
        .resume()
    }
}

extension TransactionsByTagVC: UITableViewDelegate, UITableViewDataSource {
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
        let transactionCell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.transactionCell, for: indexPath)!
        
        let noTransactionsCell = tableView.dequeueReusableCell(withIdentifier: "noTransactionsCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.filteredTransactions.isEmpty && self.transactionsError.isEmpty && self.transactionsErrorResponse.isEmpty && !self.refreshControl.isRefreshing {
            tableView.separatorStyle = .none
            
            noTransactionsCell.selectionStyle = .none
            noTransactionsCell.textLabel?.font = circularStdBook
            noTransactionsCell.textLabel?.textColor = .white
            noTransactionsCell.textLabel?.textAlignment = .center
            noTransactionsCell.textLabel?.text = "No Transactions"
            noTransactionsCell.backgroundColor = .clear
            
            return noTransactionsCell
        } else {
            tableView.separatorStyle = .singleLine
            
            if !self.transactionsError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.font = circularStdBook
                errorStringCell.textLabel?.text = transactionsError
                
                return errorStringCell
            } else if !self.transactionsErrorResponse.isEmpty {
                let error = transactionsErrorResponse[indexPath.row]
                
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .red
                errorObjectCell.textLabel?.font = circularStdBold
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
                errorObjectCell.detailTextLabel?.text = error.detail
                
                return errorObjectCell
            } else {
                let transaction = filteredTransactions[indexPath.row]
                
                transactionCell.selectedBackgroundView = bgCellView
                transactionCell.leftLabel.text = transaction.attributes.description
                transactionCell.leftSubtitle.text = transaction.attributes.creationDate
                
                if transaction.attributes.amount.valueInBaseUnits.signum() == -1 {
                    transactionCell.rightLabel.textColor = .black
                } else {
                    transactionCell.rightLabel.textColor = R.color.greenColour()
                }
                
                transactionCell.rightLabel.text = transaction.attributes.amount.valueShort
                
                return transactionCell
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.transactionsErrorResponse.isEmpty && self.transactionsError.isEmpty && !self.filteredTransactions.isEmpty {
            let vc = TransactionDetailVC(style: .insetGrouped)
            
            vc.transaction = filteredTransactions[indexPath.row]
            vc.categories = self.categories
            vc.accounts = self.accounts
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if self.transactionsErrorResponse.isEmpty && self.transactionsError.isEmpty && !self.filteredTransactions.isEmpty {
            let transaction = filteredTransactions[indexPath.row]
            
            let copy = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                UIPasteboard.general.string = transaction.attributes.description
            }
            let remove = UIAction(title: "Remove", image: R.image.trash(), attributes: .destructive) { _ in
                #if !targetEnvironment(macCatalyst)
                let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let confirmAction = UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
                    let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!
                    var request = URLRequest(url: url)
                    
                    request.httpMethod = "DELETE"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("Bearer \(appDefaults.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
                    
                    let bodyObject: [String : Any] = [
                        "data": [
                            [
                                "type": "tags",
                                "id": self.tag.id
                            ]
                        ]
                    ]
                    
                    request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
                    
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if error == nil {
                            let statusCode = (response as! HTTPURLResponse).statusCode
                            if statusCode != 204 {
                                DispatchQueue.main.async {
                                    let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)
                                    
                                    let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                                    let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]
                                    
                                    let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                                    let messageAttrString = NSMutableAttributedString(string: "\(self.tag.id) was not removed from \(transaction.attributes.description).", attributes: messageFont)
                                    
                                    ac.setValue(titleAttrString, forKey: "attributedTitle")
                                    ac.setValue(messageAttrString, forKey: "attributedMessage")
                                    
                                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                                    dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                                    ac.addAction(dismissAction)
                                    self.present(ac, animated: true)
                                    
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.listTransactions()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)
                                
                                let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                                let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]
                                
                                let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                                let messageAttrString = NSMutableAttributedString(string: error?.localizedDescription ?? "\(self.tag.id) was not removed from \(transaction.attributes.description).", attributes: messageFont)
                                
                                ac.setValue(titleAttrString, forKey: "attributedTitle")
                                ac.setValue(messageAttrString, forKey: "attributedMessage")
                                
                                let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                                dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                                ac.addAction(dismissAction)
                                self.present(ac, animated: true)
                            }
                        }
                    }
                    .resume()
                })
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                ac.addAction(confirmAction)
                ac.addAction(cancelAction)
                self.present(ac, animated: true)
                #else
                let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!
                var request = URLRequest(url: url)
                
                request.httpMethod = "DELETE"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("Bearer \(appDefaults.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
                
                let bodyObject: [String : Any] = [
                    "data": [
                        [
                            "type": "tags",
                            "id": self.tag.id
                        ]
                    ]
                ]
                
                request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if error == nil {
                        let statusCode = (response as! HTTPURLResponse).statusCode
                        if statusCode != 204 {
                            DispatchQueue.main.async {
                                let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)
                                
                                let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                                let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]
                                
                                let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                                let messageAttrString = NSMutableAttributedString(string: "\(self.tag.id) was not removed from \(transaction.attributes.description).", attributes: messageFont)
                                
                                ac.setValue(titleAttrString, forKey: "attributedTitle")
                                ac.setValue(messageAttrString, forKey: "attributedMessage")
                                
                                let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                                dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                                ac.addAction(dismissAction)
                                self.present(ac, animated: true)
                                
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.listTransactions()
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)
                            
                            let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                            let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]
                            
                            let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                            let messageAttrString = NSMutableAttributedString(string: error?.localizedDescription ?? "\(self.tag.id) was not removed from \(transaction.attributes.description).", attributes: messageFont)
                            
                            ac.setValue(titleAttrString, forKey: "attributedTitle")
                            ac.setValue(messageAttrString, forKey: "attributedMessage")
                            
                            let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                            dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                            ac.addAction(dismissAction)
                            self.present(ac, animated: true)
                        }
                    }
                }
                .resume()
                #endif
            }
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                UIMenu(children: [copy, remove])
            }
        } else {
            return nil
        }
    }
}

extension TransactionsByTagVC: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if self.filteredTransactions != self.prevFilteredTransactions {
            self.tableViewController.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
        self.prevFilteredTransactions = self.filteredTransactions
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searchBar.text = ""
            self.prevFilteredTransactions = self.filteredTransactions
            self.tableViewController.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
}
