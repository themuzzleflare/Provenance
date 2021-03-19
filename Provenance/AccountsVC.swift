import UIKit
import TinyConstraints
import Rswift

class AccountsVC: ViewController {
    let fetchingView = ActivityIndicator(style: .medium)
    let tableViewController = TableViewController(style: .insetGrouped)
    let refreshControl = RefreshControl(frame: .zero)
    
    private var accounts: [AccountResource] = []
    private var accountsErrorResponse: [ErrorObject] = []
    private var accountsError: String = ""
    
    @objc private func refreshAccounts() {
        #if targetEnvironment(macCatalyst)
        let loadingView = ActivityIndicator(style: .medium)
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loadingView), animated: true)
        #endif
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.listAccounts()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigation()
        setupRefreshControl()
        setupFetchingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        listAccounts()
    }
    
    private func setProperties() {
        title = "Accounts"
    }
    
    private func setupNavigation() {
        navigationItem.title = "Loading"
        navigationController?.navigationBar.prefersLargeTitles = true
        #if targetEnvironment(macCatalyst)
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshAccounts)), animated: true)
        #endif
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshAccounts), for: .valueChanged)
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
        
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "accountCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noAccountsCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    private func listAccounts() {
        var url = URL(string: "https://api.up.com.au/api/v1/accounts")!
        let urlParams = ["page[size]":"100"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Account.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Accounts JSON decoding succeeded")
                        self.accounts = decodedResponse.data
                        self.accountsError = ""
                        self.accountsErrorResponse = []
                        self.navigationItem.title = "Accounts"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAccounts)), animated: true)
                        #endif
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Accounts Error JSON decoding succeeded")
                        self.accountsErrorResponse = decodedResponse.errors
                        self.accountsError = ""
                        self.accounts = []
                        self.navigationItem.title = "Errors"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAccounts)), animated: true)
                        #endif
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Accounts JSON decoding failed")
                        self.accountsError = "JSON Decoding Failed!"
                        self.accountsErrorResponse = []
                        self.accounts = []
                        self.navigationItem.title = "Error"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAccounts)), animated: true)
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
                    self.accountsError = error?.localizedDescription ?? "Unknown Error!"
                    self.accountsErrorResponse = []
                    self.accounts = []
                    self.navigationItem.title = "Error"
                    #if targetEnvironment(macCatalyst)
                    self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAccounts)), animated: true)
                    #endif
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
        }
        .resume()
    }
}

extension AccountsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.accounts.isEmpty && self.accountsError.isEmpty && self.accountsErrorResponse.isEmpty {
            return 1
        } else {
            if !self.accountsError.isEmpty {
                return 1
            } else if !self.accountsErrorResponse.isEmpty {
                return accountsErrorResponse.count
            } else {
                return accounts.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let accountCell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath) as! SubtitleTableViewCell
        
        let noAccountsCell = tableView.dequeueReusableCell(withIdentifier: "noAccountsCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.accounts.isEmpty && self.accountsError.isEmpty && self.accountsErrorResponse.isEmpty && !self.refreshControl.isRefreshing {
            tableView.separatorStyle = .none
            
            noAccountsCell.selectionStyle = .none
            noAccountsCell.textLabel?.font = circularStdBook
            noAccountsCell.textLabel?.textColor = .white
            noAccountsCell.textLabel?.textAlignment = .center
            noAccountsCell.textLabel?.text = "No Accounts"
            noAccountsCell.backgroundColor = .clear
            
            return noAccountsCell
        } else {
            tableView.separatorStyle = .singleLine
            
            if !self.accountsError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.font = circularStdBook
                errorStringCell.textLabel?.text = accountsError
                
                return errorStringCell
            } else if !self.accountsErrorResponse.isEmpty {
                let error = accountsErrorResponse[indexPath.row]
                
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .red
                errorObjectCell.textLabel?.font = circularStdBold
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
                errorObjectCell.detailTextLabel?.text = error.detail
                
                return errorObjectCell
            } else {
                let account = accounts[indexPath.row]
                
                accountCell.selectedBackgroundView = bgCellView
                accountCell.accessoryType = .disclosureIndicator
                accountCell.textLabel?.font = circularStdBold
                accountCell.textLabel?.textColor = .black
                accountCell.textLabel?.text = account.attributes.displayName
                accountCell.detailTextLabel?.textColor = .darkGray
                accountCell.detailTextLabel?.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
                accountCell.detailTextLabel?.text = account.attributes.balance.valueShort
                
                return accountCell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.accountsErrorResponse.isEmpty && self.accountsError.isEmpty && !self.accounts.isEmpty {
            let vc = TransactionsByAccountVC()
            
            vc.account = accounts[indexPath.row]
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
