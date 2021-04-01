import UIKit
import MarqueeLabel
import Rswift

class TransactionDetailVC: TableViewController {
    var transaction: TransactionResource!
    var categories: [CategoryResource]!
    var accounts: [AccountResource]!
    
    let scrollingTitle = MarqueeLabel()
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, DetailAttribute>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, DetailAttribute>
    
    private lazy var sections: [Section] = [
        Section(title: "Section 1", detailAttributes: [
            DetailAttribute(
                titleKey: "Status",
                titleValue: transaction.attributes.statusString
            ),
            DetailAttribute(
                titleKey: "Account",
                titleValue: accountFilter?.first?.attributes.displayName ?? ""
            )
        ]),
        Section(title: "Section 2", detailAttributes: [
            DetailAttribute(
                titleKey: "Description",
                titleValue: transaction.attributes.description
            ),
            DetailAttribute(
                titleKey: "Raw Text",
                titleValue: transaction.attributes.rawText ?? ""
            ),
            DetailAttribute(
                titleKey: "Message",
                titleValue: transaction.attributes.message ?? ""
            )
        ]),
        Section(title: "Section 3", detailAttributes: [
            DetailAttribute(
                titleKey: "Hold \(transaction.attributes.holdInfo?.amount.transactionType ?? "")",
                titleValue: holdTransValue
            ),
            DetailAttribute(
                titleKey: "Hold Foreign \(transaction.attributes.holdInfo?.foreignAmount?.transactionType ?? "")",
                titleValue: holdForeignTransValue
            ),
            DetailAttribute(
                titleKey: "Foreign \(transaction.attributes.foreignAmount?.transactionType ?? "")",
                titleValue: holdForeignTransValue
            ),
            DetailAttribute(
                titleKey: transaction.attributes.amount.transactionType,
                titleValue: transaction.attributes.amount.valueLong
            )
        ]),
        Section(title: "Section 4", detailAttributes: [
            DetailAttribute(
                titleKey: "Creation Date",
                titleValue: transaction.attributes.creationDate
            ),
            DetailAttribute(
                titleKey: "Settlement Date",
                titleValue: transaction.attributes.settlementDate ?? ""
            )
        ]),
        Section(title: "Section 5", detailAttributes: [
            DetailAttribute(
                titleKey: "Parent Category",
                titleValue: parentCategoryFilter?.first?.attributes.name ?? ""
            ),
            DetailAttribute(
                titleKey: "Category",
                titleValue: categoryFilter?.first?.attributes.name ?? ""
            )
        ]),
        Section(title: "Section 6", detailAttributes: [
            DetailAttribute(
                titleKey: "Tags",
                titleValue: transaction.relationships.tags.data.count.description
            )
        ])
    ]
    private lazy var dataSource = makeDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureProperties()
        configureMarqueeLabel()
        configureNavigation()
        configureTableView()
        
        applySnapshot(animatingDifferences: false)
    }
}

extension TransactionDetailVC {
    private var filteredSections: [Section] {
        sections.filter { section in
            !section.detailAttributes.allSatisfy { detailAttribute in
                detailAttribute.titleValue == "" || (detailAttribute.titleKey == "Tags" && detailAttribute.titleValue == "0")
            }
        }
    }
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
    
    private func makeDataSource() -> DataSource {
        return DataSource(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, detailAttribute in
                let cell = tableView.dequeueReusableCell(withIdentifier: AttributeCell.reuseIdentifier, for: indexPath) as! AttributeCell
                
                var cellSelectionStyle: UITableViewCell.SelectionStyle {
                    switch detailAttribute.titleKey {
                        case "Account", "Parent Category", "Category", "Tags": return .default
                        default: return .none
                    }
                }
                var cellAccessoryType: UITableViewCell.AccessoryType {
                    switch detailAttribute.titleKey {
                        case "Account", "Parent Category", "Category", "Tags": return .disclosureIndicator
                        default: return .none
                    }
                }
                var cellRightDetailFont: UIFont {
                    switch detailAttribute.titleKey {
                        case "Raw Text": return R.font.sfMonoRegular(size: UIFont.labelFontSize)!
                        default: return R.font.circularStdBook(size: UIFont.labelFontSize)!
                    }
                }
                
                cell.selectionStyle = cellSelectionStyle
                cell.accessoryType = cellAccessoryType
                
                cell.leftLabel.text = detailAttribute.titleKey
                
                cell.rightLabel.font = cellRightDetailFont
                cell.rightLabel.text = detailAttribute.titleValue
                
                return cell
            }
        )
    }
    private func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        
        snapshot.appendSections(filteredSections)
        
        filteredSections.forEach { section in
            snapshot.appendItems(section.detailAttributes.filter { detailAttribute in
                detailAttribute.titleValue != ""
            }, toSection: section)
        }
        
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    private func configureProperties() {
        title = "Transaction Details"
    }
    
    private func configureMarqueeLabel() {
        scrollingTitle.speed = .rate(65)
        scrollingTitle.fadeLength = 20
        
        scrollingTitle.textAlignment = .center
        scrollingTitle.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        scrollingTitle.text = transaction.attributes.description
    }
    
    private func configureNavigation() {
        navigationItem.titleView = scrollingTitle
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.setRightBarButton(UIBarButtonItem(customView: transaction.attributes.statusIconView), animated: true)
    }
    
    private func configureTableView() {
        tableView.register(AttributeCell.self, forCellReuseIdentifier: AttributeCell.reuseIdentifier)
        tableView.dataSource = dataSource
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let attribute = dataSource.itemIdentifier(for: indexPath)!
        
        if attribute.titleKey == "Account" {
            let vc = R.storyboard.transactionsByAccount.transactionsByAccountController()!
            
            vc.account = accountFilter!.first!
            
            navigationController?.pushViewController(vc, animated: true)
        } else if attribute.titleKey == "Parent Category" || attribute.titleKey == "Category" {
            let vc = TransactionsByCategoryVC()
            
            if attribute.titleKey == "Parent Category" {
                vc.category = parentCategoryFilter!.first
            } else {
                vc.category = categoryFilter!.first
            }
            
            navigationController?.pushViewController(vc, animated: true)
        } else if attribute.titleKey == "Tags" {
            let vc = TagsVC(style: .insetGrouped)
            
            vc.transaction = transaction
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
