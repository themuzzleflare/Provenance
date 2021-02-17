import UIKit

class TransactionDetailVC: UITableViewController {
    var transaction: TransactionResource!
    var categories: [CategoryResource]!
    var accounts: [AccountResource]!
    
    private var createdDate: String {
        switch UserDefaults.standard.string(forKey: "dateStyle") {
            case "Absolute", .none: return transaction.attributes.createdDate
            case "Relative": return transaction.attributes.createdDateRelative
            default: return transaction.attributes.createdDate
        }
    }
    
    private var settledDate: String {
        switch UserDefaults.standard.string(forKey: "dateStyle") {
            case "Absolute", .none: return transaction.attributes.settledDate ?? ""
            case "Relative": return transaction.attributes.settledDateRelative ?? ""
            default: return transaction.attributes.settledDate ?? ""
        }
    }
    
    private var statusString: String {
        switch transaction?.attributes.isSettled {
            case true: return "Settled"
            case false: return "Held"
            default: return ""
        }
    }
    
    private var statusIcon: UIImageView {
        let configuration = UIImage.SymbolConfiguration(pointSize: 20)
        
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
    
    private var holdTransValue: String {
        if transaction.attributes.holdInfo != nil {
            if transaction.attributes.holdInfo!.amount.value != transaction.attributes.amount.value {
                return "\(transaction.attributes.holdInfo!.amount.valueSymbol)\(transaction.attributes.holdInfo!.amount.valueString) \(transaction.attributes.holdInfo!.amount.currencyCode)"
            } else {
                return ""
            }
        } else {
            return ""
        }
    }
    
    private var holdForeignTransValue: String {
        if transaction.attributes.holdInfo?.foreignAmount != nil {
            if transaction.attributes.holdInfo!.foreignAmount!.value != transaction.attributes.foreignAmount!.value {
                return "\(transaction.attributes.holdInfo!.foreignAmount!.valueSymbol)\(transaction.attributes.holdInfo!.foreignAmount!.valueString) \(transaction.attributes.holdInfo!.foreignAmount!.currencyCode)"
            } else {
                return ""
            }
        } else {
            return ""
        }
    }
    
    private var foreignTransValue: String {
        if transaction.attributes.foreignAmount != nil {
            return "\(transaction.attributes.foreignAmount!.valueSymbol)\(transaction.attributes.foreignAmount!.valueString) \(transaction.attributes.foreignAmount!.currencyCode)"
        } else {
            return ""
        }
    }
    
    private var attributes: KeyValuePairs<String, String> {
        return ["Status": statusString, "Account": accountFilter?.first?.attributes.displayName ?? ""]
    }
    
    private var attributesTwo: KeyValuePairs<String, String> {
        return ["Description": transaction?.attributes.description ?? "", "Raw Text": transaction?.attributes.rawText ?? "", "Message": transaction?.attributes.message ?? ""]
    }
    
    private var attributesThree: KeyValuePairs<String, String> {
        return ["Hold \(transaction.attributes.holdInfo?.amount.transType ?? "")": holdTransValue, "Hold Foreign \(transaction.attributes.holdInfo?.foreignAmount?.transType ?? "")": holdForeignTransValue, "Foreign \(transaction.attributes.foreignAmount?.transType ?? "")": foreignTransValue, transaction?.attributes.amount.transType ?? "Amount": "\(transaction?.attributes.amount.valueSymbol ?? "")\(transaction?.attributes.amount.valueString ?? "") \(transaction?.attributes.amount.currencyCode ?? "")"]
    }
    
    private var attributesFour: KeyValuePairs<String, String> {
        return ["Created Date": createdDate, "Settled Date": settledDate]
    }
    
    private var attributesFive: KeyValuePairs<String, String> {
        return ["Parent Category": parentCategoryFilter?.first?.attributes.name ?? "", "Category": categoryFilter?.first?.attributes.name ?? ""]
    }
    
    private var attributesSix: KeyValuePairs<String, String> {
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
    
    private var altAttributesFour: Array<(key: String, value: String)> {
        return attributesFour.filter {
            $0.value != ""
        }
    }
    
    private var altAttributesFive: Array<(key: String, value: String)> {
        return attributesFive.filter {
            $0.value != ""
        }
    }
    
    private var altAttributesSix: Array<(key: String, value: String)> {
        return attributesSix.filter {
            $0.value != ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let statusButtonIcon = UIBarButtonItem(customView: statusIcon)
        
        clearsSelectionOnViewWillAppear = true
        
        title = "Transaction Details"
        navigationItem.title = transaction?.attributes.description ?? ""
        navigationItem.setRightBarButton(statusButtonIcon, animated: true)
        tableView.register(UINib(nibName: "AttributeCell", bundle: nil), forCellReuseIdentifier: "attributeCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if transaction?.relationships.tags.data.count == 0 && (transaction?.relationships.parentCategory.data == nil && transaction?.relationships.category.data == nil) {
            return 4
        } else if transaction?.relationships.tags.data.count == 0 || (transaction?.relationships.parentCategory.data == nil && transaction?.relationships.category.data == nil) {
            return 5
        } else {
            return 6
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return altAttributes.count
        } else if section == 1 {
            return altAttributesTwo.count
        } else if section == 2 {
            return altAttributesThree.count
        } else if section == 3 {
            return altAttributesFour.count
        } else if section == 4 {
            return altAttributesFive.count
        } else {
            return altAttributesSix.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "attributeCell", for: indexPath) as! AttributeCell
        
        let attribute: (key: String, value: String)
        
        let section = indexPath.section
        
        if section == 0 {
            attribute = altAttributes[indexPath.row]
            
            if attribute.key == "Account" {
                cell.selectionStyle = .default
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.selectionStyle = .none
                cell.accessoryType = .none
            }
        } else if section == 1 {
            attribute = altAttributesTwo[indexPath.row]
            
            if attribute.key == "Raw Text" {
                cell.rightDetail.font = UIFont(name: "SFMono-Regular", size: UIFont.labelFontSize)
            } else {
                cell.selectionStyle = .none
                cell.accessoryType = .none
            }
        } else if section == 2 {
            attribute = altAttributesThree[indexPath.row]
        } else if section == 3 {
            attribute = altAttributesFour[indexPath.row]
        } else if section == 4 {
            attribute = altAttributesFive[indexPath.row]
            
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
        } else {
            attribute = altAttributesSix[indexPath.row]
            
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
        }
        
        cell.leftLabel.text = attribute.key
        cell.rightDetail.text = attribute.value
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let attribute: (key: String, value: String)
        
        if section == 0 {
            attribute = altAttributes[indexPath.row]
            
            if attribute.key == "Account" {
                let vc = TransactionsByAccountVC()
                vc.account = accountFilter!.first!
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if section == 4 {
            attribute = altAttributesFive[indexPath.row]
            
            let vc = TransactionsByCategoryVC()
            
            if attribute.key == "Parent Category" {
                vc.category = parentCategoryFilter!.first
            } else {
                vc.category = categoryFilter!.first
            }
            navigationController?.pushViewController(vc, animated: true)
        } else if section == 5 {
            let vc = TagsVC(style: .grouped)
            vc.transaction = transaction
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let section = indexPath.section
        
        if section == 1 {
            let attribute = altAttributesTwo[indexPath.row]
            
            let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = attribute.value
            }
            
            return UIContextMenuConfiguration(identifier: nil,
                                              previewProvider: nil) { _ in
                UIMenu(title: "", children: [copy])
            }
        } else {
            return nil
        }
    }
}
