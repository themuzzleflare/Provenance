import UIKit
import Alamofire
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
            self.fetchAccounts()
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
        fetchAccounts()
    }
    
    private func setProperties() {
        title = "Accounts"
    }
    
    private func setupNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.walletPass(), style: .plain, target: self, action: nil)
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
    
    private func fetchAccounts() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        AF.request(UpApi.Accounts().listAccounts, method: .get, parameters: pageSize100Param, headers: headers).responseJSON { response in
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Account.self, from: response.data!) {
                        print("Accounts JSON decoding succeeded")
                        self.accounts = decodedResponse.data
                        self.accountsError = ""
                        self.accountsErrorResponse = []
                        self.navigationItem.title = "Accounts"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAccounts)), animated: true)
                        #endif
                        if self.fetchingView.isDescendant(of: self.view) {
                            self.fetchingView.removeFromSuperview()
                        }
                        if !self.tableViewController.tableView.isDescendant(of: self.view) {
                            self.setupTableView()
                        }
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        print("Accounts Error JSON decoding succeeded")
                        self.accountsErrorResponse = decodedResponse.errors
                        self.accountsError = ""
                        self.accounts = []
                        self.navigationItem.title = "Errors"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAccounts)), animated: true)
                        #endif
                        if self.fetchingView.isDescendant(of: self.view) {
                            self.fetchingView.removeFromSuperview()
                        }
                        if !self.tableViewController.tableView.isDescendant(of: self.view) {
                            self.setupTableView()
                        }
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    } else {
                        print("Accounts JSON decoding failed")
                        self.accountsError = "JSON Decoding Failed!"
                        self.accountsErrorResponse = []
                        self.accounts = []
                        self.navigationItem.title = "Error"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAccounts)), animated: true)
                        #endif
                        if self.fetchingView.isDescendant(of: self.view) {
                            self.fetchingView.removeFromSuperview()
                        }
                        if !self.tableViewController.tableView.isDescendant(of: self.view) {
                            self.setupTableView()
                        }
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
                    self.accountsError = response.error?.localizedDescription ?? "Unknown Error!"
                    self.accountsErrorResponse = []
                    self.accounts = []
                    self.navigationItem.title = "Error"
                    #if targetEnvironment(macCatalyst)
                    self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAccounts)), animated: true)
                    #endif
                    if self.fetchingView.isDescendant(of: self.view) {
                        self.fetchingView.removeFromSuperview()
                    }
                    if !self.tableViewController.tableView.isDescendant(of: self.view) {
                        self.setupTableView()
                    }
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
            }
        }
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let accountCell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath) as! SubtitleTableViewCell
        
        let noAccountsCell = tableView.dequeueReusableCell(withIdentifier: "noAccountsCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.accounts.isEmpty && self.accountsError.isEmpty && self.accountsErrorResponse.isEmpty {
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
                accountCell.accessoryType = .none
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
            let vc = R.storyboard.transactionsByAccount.transactionsByAccountController()!
            
            vc.account = accounts[indexPath.row]
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
