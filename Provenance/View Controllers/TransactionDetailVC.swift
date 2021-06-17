import UIKit
import Alamofire
import MarqueeLabel
import Rswift

class TransactionDetailVC: TableViewController {
    // MARK: - Properties

    var transaction: TransactionResource!
    var categories: [CategoryResource]?
    var accounts: [AccountResource]?

    private typealias DataSource = UITableViewDiffableDataSource<Section, DetailAttribute>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, DetailAttribute>

    private lazy var dataSource = makeDataSource()

    private let scrollingTitle = MarqueeLabel()

    private var dateStyleObserver: NSKeyValueObservation?
    private var sections: [Section]!
    private var filteredSections: [Section] {
        sections.filter { section in
            !section.detailAttributes.allSatisfy { attribute in
                attribute.value.isEmpty || (attribute.key == "Tags" && attribute.value == "0")
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
    private var transferAccountFilter: [AccountResource]? {
        accounts?.filter { taccount in
            transaction.relationships.transferAccount.data?.id == taccount.id
        }
    }
    private var holdTransValue: String {
        switch transaction.attributes.holdInfo {
            case nil:
                return ""
            default:
                switch transaction.attributes.holdInfo!.amount.value {
                    case transaction.attributes.amount.value:
                        return ""
                    default:
                        return transaction.attributes.holdInfo!.amount.valueLong
                }
        }
    }
    private var holdForeignTransValue: String {
        switch transaction.attributes.holdInfo?.foreignAmount {
            case nil:
                return ""
            default:
                switch transaction.attributes.holdInfo!.foreignAmount!.value {
                    case transaction.attributes.foreignAmount!.value:
                        return ""
                    default:
                        return transaction.attributes.holdInfo!.foreignAmount!.valueLong
                }
        }
    }
    private var foreignTransValue: String {
        switch transaction.attributes.foreignAmount {
            case nil:
                return ""
            default:
                return transaction.attributes.foreignAmount!.valueLong
        }
    }

    // MARK: - View Life Cycle

    override init(style: UITableView.Style) {
        super.init(style: style)
        configureProperties()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureScrollingTitle()
        configureNavigation()
        configureTableView()
        applySnapshot()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchTransaction()
    }
}

// MARK: - Configuration

private extension TransactionDetailVC {
    private func configureProperties() {
        title = "Transaction Details"
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { object, change in
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
        navigationItem.title = transaction.attributes.description
        navigationItem.titleView = scrollingTitle
        navigationItem.setRightBarButton(UIBarButtonItem(image: transaction.attributes.statusIcon, style: .plain, target: self, action: #selector(openStatusIconHelpView)), animated: false)
        navigationItem.rightBarButtonItem?.tintColor = transaction.attributes.isSettled ? .systemGreen : .systemYellow
    }
    
    private func configureTableView() {
        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: AttributeTableViewCell.reuseIdentifier)
    }
}

// MARK: - Actions

private extension TransactionDetailVC {
    @objc private func appMovedToForeground() {
        fetchTransaction()
    }

    @objc private func openStatusIconHelpView() {
        present(NavigationController(rootViewController: StatusIconHelpView()), animated: true)
    }

    private func makeDataSource() -> DataSource {
        DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, attribute in
                let cell = tableView.dequeueReusableCell(withIdentifier: AttributeTableViewCell.reuseIdentifier, for: indexPath) as! AttributeTableViewCell
                var cellSelectionStyle: UITableViewCell.SelectionStyle {
                    switch attribute.key {
                        case "Account", "Transfer Account", "Parent Category", "Category", "Tags":
                            return .default
                        default:
                            return .none
                    }
                }
                var cellAccessoryType: UITableViewCell.AccessoryType {
                    switch attribute.key {
                        case "Account", "Transfer Account", "Parent Category", "Category", "Tags":
                            return .disclosureIndicator
                        default:
                            return .none
                    }
                }
                cell.selectionStyle = cellSelectionStyle
                cell.accessoryType = cellAccessoryType
                cell.leftLabel.text = attribute.key
                cell.rightLabel.font = attribute.key == "Raw Text" ? R.font.sfMonoRegular(size: UIFont.labelFontSize)! : R.font.circularStdBook(size: UIFont.labelFontSize)!
                cell.rightLabel.text = attribute.value
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
                ),
                DetailAttribute(
                    key: "Transfer Account",
                    value: transferAccountFilter?.first?.attributes.displayName ?? ""
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
            snapshot.appendItems(section.detailAttributes.filter { attribute in
                !attribute.value.isEmpty
            }, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func fetchTransaction() {
        AF.request(UpAPI.Transactions().retrieveTransaction(transactionId: transaction.id), method: .get, headers: [acceptJsonHeader, authorisationHeader]).responseJSON { response in
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(SingleTransactionResponse.self, from: response.data!) {
                        self.transaction = decodedResponse.data
                        self.applySnapshot()
                        self.configureNavigation()
                    } else {
                        print("JSON decoding failed")
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension TransactionDetailVC {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let attribute = dataSource.itemIdentifier(for: indexPath)!
        tableView.deselectRow(at: indexPath, animated: true)
        if attribute.key == "Account" {
            navigationController?.pushViewController({let vc = TransactionsByAccountVC(style: .insetGrouped);vc.account = accountFilter!.first!;return vc}(), animated: true)
        } else if attribute.key == "Transfer Account" {
            navigationController?.pushViewController({let vc = TransactionsByAccountVC(style: .insetGrouped);vc.account = transferAccountFilter!.first!;return vc}(), animated: true)
        } else if attribute.key == "Parent Category" || attribute.key == "Category" {
            let vc = TransactionsByCategoryVC(style: .insetGrouped)
            if attribute.key == "Parent Category" {
                vc.category = parentCategoryFilter!.first
            } else {
                vc.category = categoryFilter!.first
            }
            navigationController?.pushViewController(vc, animated: true)
        } else if attribute.key == "Tags" {
            navigationController?.pushViewController({let vc = TagsVC(style: .insetGrouped);vc.transaction = transaction;return vc}(), animated: true)
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
                        UIAction(title: "Copy \(attribute.key)", image: R.image.docOnClipboard()) { action in
                            UIPasteboard.general.string = attribute.value
                        }
                    ])
                }
        }
    }
}
