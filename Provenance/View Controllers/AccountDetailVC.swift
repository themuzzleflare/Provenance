import UIKit
import Rswift

class AccountDetailVC: TableViewController {
    var account: AccountResource!
    var transaction: TransactionResource?
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, DetailAttribute>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, DetailAttribute>

    private var dateStyleObserver: NSKeyValueObservation?
    private var sections: [Section]!

    private lazy var dataSource = makeDataSource()
    
    private func makeDataSource() -> DataSource {
        return DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, detailAttribute in
                let cell = tableView.dequeueReusableCell(withIdentifier: AttributeTableViewCell.reuseIdentifier, for: indexPath) as! AttributeTableViewCell
                cell.leftLabel.text = detailAttribute.key
                cell.rightLabel.font = detailAttribute.key == "Account ID" ? R.font.cousineRegular(size: UIFont.labelFontSize)! : R.font.circularStdBook(size: UIFont.labelFontSize)!
                cell.rightLabel.text = detailAttribute.value
                return cell
            }
        )
    }

    private func applySnapshot() {
        sections = [
            Section(title: "Section 1", detailAttributes: [
                DetailAttribute(
                    key: "Account Balance",
                    value: account.attributes.balance.valueLong
                ),
                DetailAttribute(
                    key: "Latest Transaction",
                    value: transaction?.attributes.description ?? ""
                ),
                DetailAttribute(
                    key: "Account ID",
                    value: account.id
                ),
                DetailAttribute(
                    key: "Creation Date",
                    value: account.attributes.creationDate
                )
            ])
        ]
        var snapshot = Snapshot()
        snapshot.appendSections(sections)
        sections.forEach { section in
            snapshot.appendItems(section.detailAttributes.filter { detailAttribute in
                !detailAttribute.value.isEmpty
            }, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    @objc private func closeWorkflow() {
        navigationController?.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setProperties()
        setupNavigation()
        setupTableView()
        applySnapshot()
    }
    
    private func setProperties() {
        title = "Account Details"
        dateStyleObserver = appDefaults.observe(\.dateStyle, options: [.new, .old]) { (object, change) in
            self.applySnapshot()
        }
    }
    
    private func setupNavigation() {
        navigationItem.title = account.attributes.displayName
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func setupTableView() {
        tableView.dataSource = dataSource
        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: AttributeTableViewCell.reuseIdentifier)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let attribute = dataSource.itemIdentifier(for: indexPath)!

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy \(attribute.key)", image: R.image.docOnClipboard()) { _ in
                    UIPasteboard.general.string = attribute.value
                }
            ])
        }
    }
}
