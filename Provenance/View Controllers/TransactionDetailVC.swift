import UIKit
import Alamofire
import MarqueeLabel
import Rswift

class TransactionDetailVC: TableViewController {
    var transaction: TransactionResource!
    var categories: [CategoryResource]?
    var accounts: [AccountResource]?

    private typealias DataSource = UITableViewDiffableDataSource<Section, DetailAttribute>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, DetailAttribute>

    private var dateStyleObserver: NSKeyValueObservation?
    private var sections: [Section]!
    
    private lazy var dataSource = makeDataSource()

    let scrollingTitle = MarqueeLabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureProperties()
        configureScrollingTitle()
        configureNavigation()
        configureTableView()
        applySnapshot()
    }

    override func viewWillAppear(_ animated: Bool) {
        fetchTransaction()
    }
}

private extension TransactionDetailVC {
    @objc private func appMovedToForeground() {
        fetchTransaction()
    }

    private var filteredSections: [Section] {
        sections.filter { section in
            !section.detailAttributes.allSatisfy { detailAttribute in
                detailAttribute.value.isEmpty || (detailAttribute.key == "Tags" && detailAttribute.value == "0")
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

    private func fetchTransaction() {
        AF.request("https://api.up.com.au/api/v1/transactions/\(transaction.id)", method: .get, headers: [acceptJsonHeader, authorisationHeader]).responseJSON { response in
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(SingleTransactionResponse.self, from: response.data!) {
                        self.transaction = decodedResponse.data
                        self.applySnapshot()
                    } else {
                        print("JSON decoding failed")
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
            }
        }
    }
    
    private func makeDataSource() -> DataSource {
        return DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, detailAttribute in
                let cell = tableView.dequeueReusableCell(withIdentifier: AttributeTableViewCell.reuseIdentifier, for: indexPath) as! AttributeTableViewCell
                var cellSelectionStyle: UITableViewCell.SelectionStyle {
                    switch detailAttribute.key {
                        case "Account", "Parent Category", "Category", "Tags":
                            return .default
                        default:
                            return .none
                    }
                }
                var cellAccessoryType: UITableViewCell.AccessoryType {
                    switch detailAttribute.key {
                        case "Account", "Parent Category", "Category", "Tags":
                            return .disclosureIndicator
                        default:
                            return .none
                    }
                }
                cell.selectionStyle = cellSelectionStyle
                cell.accessoryType = cellAccessoryType
                cell.leftLabel.text = detailAttribute.key
                cell.rightLabel.font = detailAttribute.key == "Raw Text" ? R.font.cousineRegular(size: UIFont.labelFontSize)! : R.font.circularStdBook(size: UIFont.labelFontSize)!
                cell.rightLabel.text = detailAttribute.value
                return cell
            }
        )
    }
    
    private func applySnapshot() {
        sections = [
            Section(title: "Section 1", detailAttributes: [
                DetailAttribute(
                    key: "Status",
                    value: transaction.attributes.statusString
                ),
                DetailAttribute(
                    key: "Account",
                    value: accountFilter?.first?.attributes.displayName ?? ""
                )
            ]),
            Section(title: "Section 2", detailAttributes: [
                DetailAttribute(
                    key: "Description",
                    value: transaction.attributes.description
                ),
                DetailAttribute(
                    key: "Raw Text",
                    value: transaction.attributes.rawText ?? ""
                ),
                DetailAttribute(
                    key: "Message",
                    value: transaction.attributes.message ?? ""
                )
            ]),
            Section(title: "Section 3", detailAttributes: [
                DetailAttribute(
                    key: "Hold \(transaction.attributes.holdInfo?.amount.transactionType ?? "")",
                    value: holdTransValue
                ),
                DetailAttribute(
                    key: "Hold Foreign \(transaction.attributes.holdInfo?.foreignAmount?.transactionType ?? "")",
                    value: holdForeignTransValue
                ),
                DetailAttribute(
                    key: "Foreign \(transaction.attributes.foreignAmount?.transactionType ?? "")",
                    value: foreignTransValue
                ),
                DetailAttribute(
                    key: transaction.attributes.amount.transactionType,
                    value: transaction.attributes.amount.valueLong
                )
            ]),
            Section(title: "Section 4", detailAttributes: [
                DetailAttribute(
                    key: "Creation Date",
                    value: transaction.attributes.creationDate
                ),
                DetailAttribute(
                    key: "Settlement Date",
                    value: transaction.attributes.settlementDate ?? ""
                )
            ]),
            Section(title: "Section 5", detailAttributes: [
                DetailAttribute(
                    key: "Parent Category",
                    value: parentCategoryFilter?.first?.attributes.name ?? ""
                ),
                DetailAttribute(
                    key: "Category",
                    value: categoryFilter?.first?.attributes.name ?? ""
                )
            ]),
            Section(title: "Section 6", detailAttributes: [
                DetailAttribute(
                    key: "Tags",
                    value: transaction.relationships.tags.data.count.description
                )
            ])
        ]
        var snapshot = Snapshot()
        snapshot.appendSections(filteredSections)
        filteredSections.forEach { section in
            snapshot.appendItems(section.detailAttributes.filter { detailAttribute in
                !detailAttribute.value.isEmpty
            }, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func configureProperties() {
        title = "Transaction Details"
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        dateStyleObserver = appDefaults.observe(\.dateStyle, options: [.new, .old]) { (object, change) in
            self.applySnapshot()
        }
    }
    
    private func configureScrollingTitle() {
        scrollingTitle.translatesAutoresizingMaskIntoConstraints = false
        scrollingTitle.speed = .rate(65)
        scrollingTitle.fadeLength = 20
        scrollingTitle.textAlignment = .center
        scrollingTitle.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        scrollingTitle.text = transaction.attributes.description
    }
    
    private func configureNavigation() {
        navigationItem.titleView = scrollingTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: transaction.attributes.statusIconView)
    }
    
    private func configureTableView() {
        tableView.dataSource = dataSource
        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: AttributeTableViewCell.reuseIdentifier)
    }
}

extension TransactionDetailVC {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let attribute = dataSource.itemIdentifier(for: indexPath)!

        tableView.deselectRow(at: indexPath, animated: true)
        
        if attribute.key == "Account" {
            navigationController?.pushViewController({let vc = TransactionsByAccountVC(style: .grouped);vc.account = accountFilter!.first!;return vc}(), animated: true)
        } else if attribute.key == "Parent Category" || attribute.key == "Category" {
            let vc = TransactionsByCategoryVC(style: .grouped)
            
            if attribute.key == "Parent Category" {
                vc.category = parentCategoryFilter!.first
            } else {
                vc.category = categoryFilter!.first
            }
            
            navigationController?.pushViewController(vc, animated: true)
        } else if attribute.key == "Tags" {
            navigationController?.pushViewController({let vc = TagsVC(style: .grouped);vc.transaction = transaction;return vc}(), animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let attribute = dataSource.itemIdentifier(for: indexPath)!
        
        switch attribute.key {
            case "Tags":
                return nil
            default:
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    UIMenu(children: [
                        UIAction(title: "Copy \(attribute.key)", image: R.image.docOnClipboard()) { _ in
                            UIPasteboard.general.string = attribute.value
                        }
                    ])
                }
        }
    }
}
