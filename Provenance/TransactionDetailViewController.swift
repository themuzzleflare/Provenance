import UIKit

class TransactionDetailViewController: UITableViewController {
    var transaction: TransactionResource!
    var categories: [CategoryResource]!
    var accounts: [AccountResource]!
    
    private var statusString: String {
        switch transaction?.attributes.isSettled {
            case true: return "Settled"
            case false: return "Held"
            default: return ""
        }
    }
    
    private var statusIcon: UIImageView {
        let configuration = UIImage.SymbolConfiguration(pointSize: 24)
        let settledIconImage = UIImage(systemName: "checkmark.circle", withConfiguration: configuration)
        let heldIconImage = UIImage(systemName: "clock", withConfiguration: configuration)
        let settledIcon = UIImageView(image: settledIconImage)
        let heldIcon = UIImageView(image: heldIconImage)
        settledIcon.tintColor = .systemGreen
        heldIcon.tintColor = .systemYellow
        switch transaction!.attributes.isSettled {
            case true: return settledIcon
            case false: return heldIcon
        }
    }
    
    private var categoryFilter: [CategoryResource]? {
        categories?.filter { category in
            transaction?.relationships.category.data?.id == category.id
        }
    }
    
    private var parentCategoryFilter: [CategoryResource]? {
        categories?.filter { pcategory in
            transaction?.relationships.parentCategory.data?.id == pcategory.id
        }
    }
    
    private var accountFilter: [AccountResource]? {
        accounts?.filter { account in
            transaction?.relationships.account.data.id == account.id
        }
    }
    
    private var attributes: KeyValuePairs<String, String> {
        return ["Description": transaction?.attributes.description ?? "", "Raw Text": transaction?.attributes.rawText ?? "", "Account": accountFilter?.first?.attributes.displayName ?? "", "Message": transaction?.attributes.message ?? "", "Status": statusString, transaction?.attributes.amount.transType ?? "Amount": "\(transaction?.attributes.amount.valueSymbol ?? "")\(transaction?.attributes.amount.valueString ?? "") \(transaction?.attributes.amount.currencyCode ?? "")", "Created Date": transaction?.attributes.createdDate ?? "", "Settled Date": transaction?.attributes.settledDate ?? ""]
    }
    
    private var attributesTwo: KeyValuePairs<String, String> {
        return ["Parent Category": parentCategoryFilter?.first?.attributes.name ?? "", "Category": categoryFilter?.first?.attributes.name ?? ""]
    }
    
    private var attributesThree: KeyValuePairs<String, String> {
        return ["Tags": transaction?.relationships.tags.data.count.description ?? ""]
    }
    
    
    private var altAttributes: Array<(key: String, value: String)> {
        return attributes.filter {
            $0.value != ""
        }
    }
    
    private var altAttributesTwo: Array<(key: String, value: String)> {
        return attributesTwo.filter {
            $0.value != ""
        }
    }
    
    private var altAttributesThree: Array<(key: String, value: String)> {
        return attributesThree.filter {
            $0.value != ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let statusButtonIcon = UIBarButtonItem(customView: statusIcon)
        
        clearsSelectionOnViewWillAppear = true
        navigationItem.title = transaction?.attributes.description ?? ""
        navigationItem.setRightBarButton(statusButtonIcon, animated: true)
        tableView.register(RightDetailTableViewCell.self, forCellReuseIdentifier: "attributeCell")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if transaction?.relationships.tags.data.count == 0 {
            return 2
        } else {
            return 3
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return altAttributes.count
        } else if section == 1 {
            return altAttributesTwo.count
        } else {
            return altAttributesThree.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "attributeCell", for: indexPath) as! RightDetailTableViewCell
        
        let attribute: (key: String, value: String)
        
        if indexPath.section == 0 {
            attribute = altAttributes[indexPath.row]
        } else if indexPath.section == 1 {
            attribute = altAttributesTwo[indexPath.row]
        } else {
            attribute = altAttributesThree[indexPath.row]
        }
        
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.textColor = .secondaryLabel
        cell.textLabel?.text = attribute.key
        cell.detailTextLabel?.textColor = .label
        cell.detailTextLabel?.textAlignment = .right
        cell.detailTextLabel?.text = attribute.value
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let attribute: (key: String, value: String)
        
        if indexPath.section == 0 || indexPath.section == 1 {
            tableView.deselectRow(at: indexPath, animated: true)
            if indexPath.section == 0 {
                attribute = altAttributes[indexPath.row]
            } else {
                attribute = altAttributesTwo[indexPath.row]
            }
            let vc = TransactionAttributeDetailViewController()
            vc.attributeKey = attribute.key
            vc.attributeValue = attribute.value
            present(UINavigationController(rootViewController: vc), animated: true)
        } else {
            let vc = TagsViewController(style: .grouped)
            vc.transaction = transaction
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
