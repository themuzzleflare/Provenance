import UIKit
import Alamofire

class AccountsVC: UIViewController, UITableViewDelegate, UISearchBarDelegate {
    let fetchingView: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    let tableViewController: UITableViewController = UITableViewController(style: .grouped)
    
    let circularStdBook = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)!
    let circularStdBold = UIFont(name: "CircularStd-Bold", size: UIFont.labelFontSize)!
    
    lazy var refreshControl: UIRefreshControl = UIRefreshControl()
    
    lazy var accounts: [AccountResource] = []
    lazy var accountsErrorResponse: [ErrorObject] = []
    lazy var accountsError: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.addChild(tableViewController)
        
        view.backgroundColor = .systemBackground
        
        title = "Accounts"
        navigationItem.title = "Loading"
        
        tableViewController.clearsSelectionOnViewWillAppear = true
        tableViewController.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshAccounts), for: .valueChanged)
        
        setupFetchingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        listAccounts()
    }
    
    @objc private func refreshAccounts() {
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
        
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "accountCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noAccountsCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    private func listAccounts() {
        let urlString = "https://api.up.com.au/api/v1/accounts"
        let parameters: Parameters = ["page[size]":"100"]
        let headers: HTTPHeaders = [
            "Accept": "application/json",
            "Authorization": "Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")"
        ]
        AF.request(urlString, method: .get, parameters: parameters, headers: headers).responseJSON { response in
            if response.error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Account.self, from: response.data!) {
                    print("Accounts JSON Decoding Succeeded!")
                    self.accounts = decodedResponse.data
                    self.accountsError = ""
                    self.accountsErrorResponse = []
                    self.navigationItem.title = "Accounts"
                    self.fetchingView.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                    print("Accounts Error JSON Decoding Succeeded!")
                    self.accountsErrorResponse = decodedResponse.errors
                    self.accountsError = ""
                    self.accounts = []
                    self.navigationItem.title = "Errors"
                    self.fetchingView.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                } else {
                    print("Accounts JSON Decoding Failed!")
                    self.accountsError = "JSON Decoding Failed!"
                    self.accountsErrorResponse = []
                    self.accounts = []
                    self.navigationItem.title = "Error"
                    self.fetchingView.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } else {
                print(response.error?.localizedDescription ?? "Unknown Error!")
                self.accountsError = response.error?.localizedDescription ?? "Unknown Error!"
                self.accountsErrorResponse = []
                self.accounts = []
                self.navigationItem.title = "Error"
                self.fetchingView.stopAnimating()
                self.fetchingView.removeFromSuperview()
                self.setupTableView()
                self.tableViewController.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
}

extension AccountsVC: UITableViewDataSource {
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
            noAccountsCell.selectionStyle = .none
            noAccountsCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
            noAccountsCell.textLabel?.text = "No Accounts"
            noAccountsCell.backgroundColor = tableView.backgroundColor
            return noAccountsCell
        } else {
            if !self.accountsError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
                errorStringCell.textLabel?.text = accountsError
                return errorStringCell
            } else if !self.accountsErrorResponse.isEmpty {
                let error = accountsErrorResponse[indexPath.row]
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .red
                errorObjectCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBold)
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.smallSystemFontSize)
                errorObjectCell.detailTextLabel?.text = error.detail
                return errorObjectCell
            } else {
                let account = accounts[indexPath.row]
                accountCell.accessoryType = .disclosureIndicator
                accountCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBold)
                accountCell.textLabel?.textColor = .label
                accountCell.textLabel?.text = account.attributes.displayName
                accountCell.detailTextLabel?.textColor = .secondaryLabel
                accountCell.detailTextLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.smallSystemFontSize)
                accountCell.detailTextLabel?.text =
                    "\(account.attributes.balance.valueSymbol)\(account.attributes.balance.valueString)"
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
