import Cocoa

class AccountsVC: NSViewController {
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var bsView: NSScrollView!
    
    lazy var accounts: [AccountResource] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bsView.translatesAutoresizingMaskIntoConstraints = false
        bsView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        bsView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        bsView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        bsView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        listAccounts()
    }
    
    override func viewWillAppear() {
        tableView.reloadData()
    }
    
    private func listAccounts() {
        var url = URL(string: "https://api.up.com.au/api/v1/accounts")!
        let urlParams = ["page[size]":"100"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer up:yeah:okHM67Kh3ibpXihwYHgtd2CRVvtv6J2TnvbZG6DVQYYKCrrYr49nHEOZ1WKRkSVLz8aayTVVNDlj9Q6alPxyEJGcXRW0kf3OgTEghgEMhA6iUNcIqOzKqRhmS3LE6Pj5", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Account.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Accounts JSON Decoding Succeeded!")
                        self.accounts = decodedResponse.data
                        self.tableView.reloadData()
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

extension AccountsVC: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return accounts.count
    }
}

extension AccountsVC: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let account = accounts[row]
        
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "nameColumn") {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
            
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            
            cellView.textField?.stringValue = account.attributes.displayName
            
            return cellView
        } else {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "balanceCell")
            
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            
            cellView.textField?.stringValue = "\(account.attributes.balance.valueSymbol)\(account.attributes.balance.valueString)"
            
            return cellView
        }
    }
}
