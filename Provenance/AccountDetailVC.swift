import UIKit

class AccountDetailVC: UITableViewController {
    var account: AccountResource!
    var transaction: TransactionResource!
    
    private var createdDate: String {
        switch UserDefaults.standard.string(forKey: "dateStyle") {
            case "Absolute", .none: return account.attributes.createdDate
            case "Relative": return account.attributes.createdDateRelative
            default: return account.attributes.createdDate
        }
    }
    
    private var attributes: KeyValuePairs<String, String> {
        return ["Account Balance": "\(account.attributes.balance.valueSymbol)\(account.attributes.balance.valueString) \(account.attributes.balance.currencyCode)", "Latest Transaction": transaction?.attributes.description ?? "", "Account ID": account.id, "Creation Date": createdDate]
    }
    
    private var altAttributes: Array<(key: String, value: String)> {
        return attributes.filter {
            $0.value != ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
        
        clearsSelectionOnViewWillAppear = true
        
        title = "Account Details"
        navigationItem.title = account.attributes.displayName
        navigationItem.rightBarButtonItem = closeButton
        tableView.register(UINib(nibName: "AttributeCell", bundle: nil), forCellReuseIdentifier: "attributeCell")
    }
    
    @objc private func closeWorkflow() {
        dismiss(animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return altAttributes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "attributeCell", for: indexPath) as! AttributeCell
        
        let attribute = altAttributes[indexPath.row]
        
        cell.leftLabel.text = attribute.key
        cell.rightDetail.text = attribute.value
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let attribute = altAttributes[indexPath.row]
        
        let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.clipboard")) { _ in
            UIPasteboard.general.string = attribute.value
        }
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            UIMenu(title: "", children: [copy])
        }
    }
}
