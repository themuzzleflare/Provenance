import UIKit
import Alamofire
import Rswift

class TransactionsByAccountVC: TableViewController {
    var account: AccountResource!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    private var transactions: [TransactionResource] = []
    private var transactionsErrorResponse: [ErrorObject] = []
    private var transactionsError: String = ""
    
    private var prevFilteredTransactions: [TransactionResource] = []
    private var categories: [CategoryResource] = []
    
    @IBOutlet var accountBalance: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureProperties()
        configureNavigation()
        configureSearch()
        configureRefreshControl()
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        
        fetchTransactions()
        fetchCategories()
    }
}

extension TransactionsByAccountVC {
    private var filteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
            searchController.searchBar.text!.isEmpty || transaction.attributes.description.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    
    @objc private func openAccountInfo() {
        let vc = AccountDetailVC(style: .insetGrouped)
        
        vc.account = account
        vc.transaction = transactions.first
        
        present(NavigationController(rootViewController: vc), animated: true)
    }
    
    @objc private func refreshTransactions() {
        #if targetEnvironment(macCatalyst)
        let loadingView = ActivityIndicator(style: .medium)
        navigationItem.setRightBarButtonItems([UIBarButtonItem(image: R.image.infoCircle(), style: .plain, target: self, action: #selector(openAccountInfo)), UIBarButtonItem(customView: loadingView)], animated: true)
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchTransactions()
            self.fetchCategories()
        }
    }
    
    private func configureProperties() {
        title = "Transactions by Account"
        
        accountBalance.text = account.attributes.balance.valueShort
    }
    
    private func configureNavigation() {
        navigationItem.largeTitleDisplayMode = .always
        
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle(), style: .plain, target: self, action: nil)
        
        #if targetEnvironment(macCatalyst)
        navigationItem.setRightBarButtonItems([UIBarButtonItem(image: R.image.infoCircle(), style: .plain, target: self, action: #selector(openAccountInfo)), UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTransactions))], animated: true)
        #else
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.infoCircle(), style: .plain, target: self, action: #selector(openAccountInfo))
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
        refreshControl = RefreshControl(frame: .zero)
        
        refreshControl?.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
    }
    
    private func configureTableView() {
        tableView.register(TransactionCell.self, forCellReuseIdentifier: TransactionCell.reuseIdentifier)
        tableView.register(LoadingTableViewCell.self, forCellReuseIdentifier: LoadingTableViewCell.reuseIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noTransactionsCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    private func fetchTransactions() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        
        AF.request(UpApi.Accounts().listTransactionsByAccount(accountId: account.id), method: .get, parameters: pageSize100Param, headers: headers).responseJSON { response in
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: response.data!) {
                        print("Transactions JSON decoding succeeded")
                        
                        self.transactions = decodedResponse.data
                        self.transactionsError = ""
                        self.transactionsErrorResponse = []
                        
                        self.navigationItem.title = self.account.attributes.displayName
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButtonItems([UIBarButtonItem(image: R.image.infoCircle(), style: .plain, target: self, action: #selector(self.openAccountInfo)), UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions))], animated: true)
                        #endif
                        
                        self.tableView.reloadData()
                        self.refreshControl?.endRefreshing()
                        
                        if self.searchController.isActive {
                            self.prevFilteredTransactions = self.filteredTransactions
                        }
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        print("Transactions Error JSON decoding succeeded")
                        
                        self.transactionsErrorResponse = decodedResponse.errors
                        self.transactionsError = ""
                        self.transactions = []
                        
                        if self.navigationItem.title != "Errors" {
                            self.navigationItem.title = "Errors"
                        }
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButtonItems([UIBarButtonItem(image: R.image.infoCircle(), style: .plain, target: self, action: #selector(self.openAccountInfo)), UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions))], animated: true)
                        #endif
                        
                        self.tableView.reloadData()
                        self.refreshControl?.endRefreshing()
                    } else {
                        print("Transactions JSON decoding failed")
                        
                        self.transactionsError = "JSON Decoding Failed!"
                        self.transactionsErrorResponse = []
                        self.transactions = []
                        
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButtonItems([UIBarButtonItem(image: R.image.infoCircle(), style: .plain, target: self, action: #selector(self.openAccountInfo)), UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions))], animated: true)
                        #endif
                        
                        self.tableView.reloadData()
                        self.refreshControl?.endRefreshing()
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
                    
                    self.transactionsError = response.error?.localizedDescription ?? "Unknown Error!"
                    self.transactionsErrorResponse = []
                    self.transactions = []
                    
                    if self.navigationItem.title != "Error" {
                        self.navigationItem.title = "Error"
                    }
                    
                    #if targetEnvironment(macCatalyst)
                    self.navigationItem.setRightBarButtonItems([UIBarButtonItem(image: R.image.infoCircle(), style: .plain, target: self, action: #selector(self.openAccountInfo)), UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions))], animated: true)
                    #endif
                    
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
            }
            self.searchController.searchBar.placeholder = "Search \(self.transactions.count.description) \(self.transactions.count == 1 ? "Transaction" : "Transactions")"
        }
    }
    
    private func fetchCategories() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        
        AF.request(UpApi.Categories().listCategories, method: .get, headers: headers).responseJSON { response in
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Category.self, from: response.data!) {
                        print("Categories JSON decoding succeeded")
                        
                        self.categories = decodedResponse.data
                    } else {
                        print("Categories JSON decoding failed")
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredTransactions.isEmpty && transactionsError.isEmpty && transactionsErrorResponse.isEmpty {
            return 1
        } else {
            if !transactionsError.isEmpty {
                return 1
            } else if !transactionsErrorResponse.isEmpty {
                return transactionsErrorResponse.count
            } else {
                return filteredTransactions.count
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let transactionCell = tableView.dequeueReusableCell(withIdentifier: TransactionCell.reuseIdentifier, for: indexPath) as! TransactionCell
        let loadingCell = tableView.dequeueReusableCell(withIdentifier: LoadingTableViewCell.reuseIdentifier, for: indexPath) as! LoadingTableViewCell
        let noTransactionsCell = tableView.dequeueReusableCell(withIdentifier: "noTransactionsCell", for: indexPath)
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if filteredTransactions.isEmpty && transactionsError.isEmpty && transactionsErrorResponse.isEmpty {
            tableView.separatorStyle = .none
            
            if transactions.isEmpty {
                loadingCell.loadingIndicator.startAnimating()
                
                return loadingCell
            } else {
                noTransactionsCell.selectionStyle = .none
                noTransactionsCell.textLabel?.font = circularStdBook
                noTransactionsCell.textLabel?.textColor = .white
                noTransactionsCell.textLabel?.textAlignment = .center
                noTransactionsCell.textLabel?.text = "No Transactions"
                noTransactionsCell.backgroundColor = .clear
                
                return noTransactionsCell
            }
        } else {
            tableView.separatorStyle = .singleLine
            
            if !transactionsError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.font = circularStdBook
                errorStringCell.textLabel?.text = transactionsError
                
                return errorStringCell
            } else if !transactionsErrorResponse.isEmpty {
                let error = transactionsErrorResponse[indexPath.row]
                
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .systemRed
                errorObjectCell.textLabel?.font = circularStdBold
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
                errorObjectCell.detailTextLabel?.text = error.detail
                
                return errorObjectCell
            } else {
                transactionCell.transaction = filteredTransactions[indexPath.row]
                
                return transactionCell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if transactionsErrorResponse.isEmpty && transactionsError.isEmpty && !filteredTransactions.isEmpty {
            let vc = TransactionDetailVC(style: .insetGrouped)
            
            vc.transaction = filteredTransactions[indexPath.row]
            vc.categories = categories
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if transactionsErrorResponse.isEmpty && transactionsError.isEmpty && !filteredTransactions.isEmpty {
            let copy = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                UIPasteboard.general.string = self.filteredTransactions[indexPath.row].attributes.description
            }
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                UIMenu(children: [copy])
            }
        } else {
            return nil
        }
    }
}

extension TransactionsByAccountVC: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if prevFilteredTransactions != filteredTransactions {
            prevFilteredTransactions = filteredTransactions
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if filteredTransactions != prevFilteredTransactions {
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
        prevFilteredTransactions = filteredTransactions
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searchBar.text = ""
            prevFilteredTransactions = filteredTransactions
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
}
