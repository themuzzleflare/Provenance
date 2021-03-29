import UIKit
import Alamofire
import TinyConstraints
import Rswift

class TransactionsByAccountVC: TableViewController {
    var account: AccountResource!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    private var transactions: [TransactionResource] = []
    private var transactionsErrorResponse: [ErrorObject] = []
    private var transactionsError: String = ""
    private var prevFilteredTransactions: [TransactionResource]? = nil
    private var categories: [CategoryResource] = []
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
    
    @IBOutlet var accountBalance: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigation()
        setupSearch()
        setupRefreshControl()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        
        fetchTransactions()
        fetchCategories()
    }
    
    private func setProperties() {
        title = "Transactions by Account"
        
        accountBalance.text = account.attributes.balance.valueShort
    }
    
    private func setupNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle(), style: .plain, target: self, action: nil)
        navigationItem.largeTitleDisplayMode = .always
        #if targetEnvironment(macCatalyst)
        navigationItem.setRightBarButtonItems([UIBarButtonItem(image: R.image.infoCircle(), style: .plain, target: self, action: #selector(openAccountInfo)), UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTransactions))], animated: true)
        #else
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.infoCircle(), style: .plain, target: self, action: #selector(openAccountInfo))
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
        refreshControl = RefreshControl(frame: .zero)
        refreshControl?.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
    }
    
    private func setupTableView() {
        tableView.register(R.nib.transactionCell)
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
                        self.navigationItem.title = "Errors"
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
                        self.navigationItem.title = "Error"
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
                    self.navigationItem.title = "Error"
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let transactionCell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.transactionCell, for: indexPath)!
        
        let loadingCell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.loadingCell, for: indexPath)!
        
        let noTransactionsCell = tableView.dequeueReusableCell(withIdentifier: "noTransactionsCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.filteredTransactions.isEmpty && self.transactionsError.isEmpty && self.transactionsErrorResponse.isEmpty {
            tableView.separatorStyle = .none
            
            if self.transactions.isEmpty {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.transactionsErrorResponse.isEmpty && self.transactionsError.isEmpty && !self.filteredTransactions.isEmpty {
            let vc = TransactionDetailVC(style: .insetGrouped)
            
            vc.transaction = filteredTransactions[indexPath.row]
            vc.categories = self.categories
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if self.transactionsErrorResponse.isEmpty && self.transactionsError.isEmpty && !self.filteredTransactions.isEmpty {
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
        if self.prevFilteredTransactions != self.filteredTransactions {
            self.prevFilteredTransactions = self.filteredTransactions
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if self.filteredTransactions != self.prevFilteredTransactions {
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
        self.prevFilteredTransactions = self.filteredTransactions
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searchBar.text = ""
            self.prevFilteredTransactions = self.filteredTransactions
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
}
