import Cocoa

class TransactionsVC: NSViewController {
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var stackView: NSStackView!
    @IBOutlet var searchField: NSSearchField!
    
    lazy var transactions: [TransactionResource] = []
    lazy var accounts: [AccountResource] = []
    lazy var categories: [CategoryResource] = []
    
    lazy var filteredTransactions: [TransactionResource] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.leftAnchor.constraint(equalTo: stackView.leftAnchor, constant: 16).isActive = true
        searchField.rightAnchor.constraint(equalTo: stackView.rightAnchor, constant: -16).isActive = true
        
        searchField.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        listTransactions()
        listAccounts()
        listCategories()
    }
    
    override func viewWillAppear() {
        tableView.reloadData()
    }
    
    private func listTransactions() {
        var url = URL(string: "https://api.up.com.au/api/v1/transactions")!
        let urlParams = ["page[size]":"100"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer up:yeah:okHM67Kh3ibpXihwYHgtd2CRVvtv6J2TnvbZG6DVQYYKCrrYr49nHEOZ1WKRkSVLz8aayTVVNDlj9Q6alPxyEJGcXRW0kf3OgTEghgEMhA6iUNcIqOzKqRhmS3LE6Pj5", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Transactions JSON Decoding Succeeded!")
                        self.transactions = decodedResponse.data
                        self.filteredTransactions = self.transactions.filter({self.searchField.stringValue.isEmpty || $0.attributes.description.localizedStandardContains(self.searchField.stringValue)})
                        self.tableView.reloadData()
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Transactions JSON Decoding Failed!")
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
    
    private func listCategories() {
        let url = URL(string: "https://api.up.com.au/api/v1/categories")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer up:yeah:okHM67Kh3ibpXihwYHgtd2CRVvtv6J2TnvbZG6DVQYYKCrrYr49nHEOZ1WKRkSVLz8aayTVVNDlj9Q6alPxyEJGcXRW0kf3OgTEghgEMhA6iUNcIqOzKqRhmS3LE6Pj5", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Category.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Categories JSON Decoding Succeeded!")
                        self.categories = decodedResponse.data
                        self.tableView.reloadData()
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
}

extension TransactionsVC: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let text = searchField.stringValue
        
        filteredTransactions = self.transactions.filter({text.isEmpty || $0.attributes.description.localizedStandardContains(text)})
        
        self.tableView.reloadData()
    }
}

extension TransactionsVC: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredTransactions.count
    }
}

extension TransactionsVC: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let transaction = filteredTransactions[row]
        
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "descriptionColumn") {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "descriptionCell")
            
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            
            cellView.textField?.stringValue = transaction.attributes.description
            
            return cellView
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "amountColumn") {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "amountCell")
            
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            
            cellView.textField?.stringValue = "\(transaction.attributes.amount.valueSymbol)\(transaction.attributes.amount.valueString)"
            
            return cellView
        } else {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "dateCell")
            
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            
            cellView.textField?.stringValue = transaction.attributes.createdDate
            
            return cellView
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let transaction = filteredTransactions[tableView.selectedRow]
        
        let vc = storyboard?.instantiateController(withIdentifier: "transDetail") as! TransactionDetailVC
        
        vc.transaction = transaction
        vc.accounts = accounts
        vc.categories = categories
        
        self.present(vc, asPopoverRelativeTo: .infinite, of: tableView.rowView(atRow: tableView.selectedRow, makeIfNecessary: false) ?? self.view, preferredEdge: .maxX, behavior: .transient)
    }
}
