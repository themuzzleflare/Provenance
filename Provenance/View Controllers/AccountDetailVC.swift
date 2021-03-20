import UIKit
import Rswift

class AccountDetailVC: TableViewController {
    var account: AccountResource!
    var transaction: TransactionResource!
    
    private var attributes: KeyValuePairs<String, String> {
        return ["Account Balance": account.attributes.balance.valueLong, "Latest Transaction": transaction?.attributes.description ?? "", "Account ID": account.id, "Creation Date": account.attributes.creationDate]
    }
    private var altAttributes: Array<(key: String, value: String)> {
        return attributes.filter {
            $0.value != ""
        }
    }
    
    @objc private func closeWorkflow() {
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigation()
        setupTableView()
    }
    
    private func setProperties() {
        title = "Account Details"
    }
    
    private func setupNavigation() {
        navigationItem.title = account.attributes.displayName
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func setupTableView() {
        tableView.register(R.nib.attributeCell)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return altAttributes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.attributeCell, for: indexPath)!
        
        let attribute = altAttributes[indexPath.row]
        
        cell.leftLabel.text = attribute.key
        cell.rightDetail.text = attribute.value
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let copy = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
            UIPasteboard.general.string = self.altAttributes[indexPath.row].value
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [copy])
        }
    }
}
