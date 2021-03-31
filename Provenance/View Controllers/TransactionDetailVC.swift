import UIKit
import MarqueeLabel
import Rswift

class TransactionDetailVC: TableViewController {
    var transaction: TransactionResource!
    var categories: [CategoryResource]!
    var accounts: [AccountResource]!
    
    let scrollingTitle = MarqueeLabel(frame: .infinite, rate: 65, fadeLength: 20)
    
    private var categoryFilter: [CategoryResource]? {
        categories?.filter { category in
            transaction.relationships.category.data?.id == category.id
        }
    }
    private var parentCategoryFilter: [CategoryResource]? {
        categories?.filter { pcategory in
            transaction.relationships.parentCategory.data?.id == pcategory.id
        }
    }
    private var accountFilter: [AccountResource]? {
        accounts?.filter { account in
            transaction.relationships.account.data.id == account.id
        }
    }
    private var holdTransValue: String {
        if transaction.attributes.holdInfo != nil {
            if transaction.attributes.holdInfo!.amount.value != transaction.attributes.amount.value {
                return transaction.attributes.holdInfo!.amount.valueLong
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
                return transaction.attributes.holdInfo!.foreignAmount!.valueLong
            } else {
                return ""
            }
        } else {
            return ""
        }
    }
    private var foreignTransValue: String {
        if transaction.attributes.foreignAmount != nil {
            return transaction.attributes.foreignAmount!.valueLong
        } else {
            return ""
        }
    }
    private var attributes: KeyValuePairs<String, String> {
        return ["Status": transaction.attributes.statusString, "Account": accountFilter?.first?.attributes.displayName ?? ""]
    }
    private var attributesTwo: KeyValuePairs<String, String> {
        return ["Description": transaction.attributes.description, "Raw Text": transaction.attributes.rawText ?? "", "Message": transaction.attributes.message ?? ""]
    }
    private var attributesThree: KeyValuePairs<String, String> {
        return ["Hold \(transaction.attributes.holdInfo?.amount.transactionType ?? "")": holdTransValue, "Hold Foreign \(transaction.attributes.holdInfo?.foreignAmount?.transactionType ?? "")": holdForeignTransValue, "Foreign \(transaction.attributes.foreignAmount?.transactionType ?? "")": foreignTransValue, transaction.attributes.amount.transactionType: transaction.attributes.amount.valueLong]
    }
    private var attributesFour: KeyValuePairs<String, String> {
        return ["Creation Date": transaction.attributes.creationDate, "Settlement Date": transaction.attributes.settlementDate ?? ""]
    }
    private var attributesFive: KeyValuePairs<String, String> {
        return ["Parent Category": parentCategoryFilter?.first?.attributes.name ?? "", "Category": categoryFilter?.first?.attributes.name ?? ""]
    }
    private var attributesSix: KeyValuePairs<String, String> {
        return ["Tags": transaction.relationships.tags.data.count.description]
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
        
        setProperties()
        setupMarqueeLabel()
        setupNavigation()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    private func setProperties() {
        title = "Transaction Details"
    }
    
    private func setupMarqueeLabel() {
        scrollingTitle.font = R.font.circularStdBook(size: 17)
        scrollingTitle.textAlignment = .center
        scrollingTitle.text = transaction.attributes.description
        
        navigationItem.titleView = scrollingTitle
    }
    
    private func setupNavigation() {
        navigationItem.setRightBarButton(UIBarButtonItem(customView: transaction.attributes.statusIconView), animated: true)
        navigationItem.largeTitleDisplayMode = .never
    }
    
    private func setupTableView() {
        tableView.register(R.nib.attributeCell)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if transaction.relationships.tags.data.count == 0 && (transaction.relationships.parentCategory.data == nil && transaction.relationships.category.data == nil) {
            return 4
        } else if transaction.relationships.tags.data.count == 0 || (transaction.relationships.parentCategory.data == nil && transaction.relationships.category.data == nil) {
            return 5
        } else {
            return 6
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case 0: return altAttributes.count
            case 1: return altAttributesTwo.count
            case 2: return altAttributesThree.count
            case 3: return altAttributesFour.count
            case 4: return transaction.relationships.parentCategory.data == nil && transaction.relationships.category.data == nil ? altAttributesSix.count : altAttributesFive.count
            case 5: return altAttributesSix.count
            default: fatalError("Unknown section")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.attributeCell, for: indexPath)!
        
        var attribute: (key: String, value: String) {
            switch indexPath.section {
                case 0: return altAttributes[indexPath.row]
                case 1: return altAttributesTwo[indexPath.row]
                case 2: return altAttributesThree[indexPath.row]
                case 3: return altAttributesFour[indexPath.row]
                case 4: return transaction.relationships.parentCategory.data == nil && transaction.relationships.category.data == nil ? altAttributesSix[indexPath.row] : altAttributesFive[indexPath.row]
                case 5: return altAttributesSix[indexPath.row]
                default: fatalError("Unknown attribute")
            }
        }
        
        var cellSelectionStyle: UITableViewCell.SelectionStyle {
            switch attribute.key {
                case "Account", "Parent Category", "Category", "Tags": return .default
                default: return .none
            }
        }
        
        var cellAccessoryType: UITableViewCell.AccessoryType {
            switch attribute.key {
                case "Account", "Parent Category", "Category", "Tags": return .disclosureIndicator
                default: return .none
            }
        }
        
        var cellRightDetailFont: UIFont {
            switch attribute.key {
                case "Raw Text": return R.font.sfMonoRegular(size: UIFont.labelFontSize)!
                default: return R.font.circularStdBook(size: UIFont.labelFontSize)!
            }
        }
        
        cell.selectedBackgroundView = bgCellView
        cell.selectionStyle = cellSelectionStyle
        cell.accessoryType = cellAccessoryType
        
        cell.leftLabel.text = attribute.key
        
        cell.rightDetail.font = cellRightDetailFont
        cell.rightDetail.text = attribute.value
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let attribute: (key: String, value: String)
        
        if section == 0 {
            attribute = altAttributes[indexPath.row]
            
            if attribute.key == "Account" {
                let vc = R.storyboard.transactionsByAccount.transactionsByAccountController()!
                
                vc.account = accountFilter!.first!
                
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if section == 4 {
            if transaction.relationships.parentCategory.data == nil && transaction.relationships.category.data == nil {
                let vc = TagsVC(style: .insetGrouped)
                
                vc.transaction = transaction
                
                navigationController?.pushViewController(vc, animated: true)
            } else {
                attribute = altAttributesFive[indexPath.row]
                
                let vc = TransactionsByCategoryVC()
                
                if attribute.key == "Parent Category" {
                    vc.category = parentCategoryFilter!.first
                } else {
                    vc.category = categoryFilter!.first
                }
                
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if section == 5 {
            let vc = TagsVC(style: .insetGrouped)
            
            vc.transaction = transaction
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if indexPath.section == 1 {
            let copy = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                UIPasteboard.general.string = self.altAttributesTwo[indexPath.row].value
            }
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                UIMenu(children: [copy])
            }
        } else {
            return nil
        }
    }
}
