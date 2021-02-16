import UIKit

class AccountDetailVC: UITableViewController {
    var account: AccountResource!
    
    private var attributes: KeyValuePairs<String, String> {
        return ["Account Balance": "\(account.attributes.balance.valueSymbol)\(account.attributes.balance.valueString) \(account.attributes.balance.currencyCode)", "Creation Date": account.attributes.createdDate]
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
        tableView.register(RightDetailTableViewCell.self, forCellReuseIdentifier: "detailCell")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath) as! RightDetailTableViewCell
        
        let attribute = altAttributes[indexPath.row]
        
        cell.selectionStyle = .none
        cell.textLabel?.textColor = .secondaryLabel
        cell.textLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)
        cell.textLabel?.text = attribute.key
        cell.detailTextLabel?.textColor = .label
        cell.detailTextLabel?.textAlignment = .right
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)
        cell.detailTextLabel?.text = attribute.value
        
        return cell
    }
}
