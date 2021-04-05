import UIKit
import Rswift

class AccountDetailVC: TableViewController {
    var account: AccountResource!
    var transaction: TransactionResource!
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, DetailAttribute>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, DetailAttribute>
    
    private var sections: [Section]!
    
    private lazy var dataSource = makeDataSource()
    
    private func makeDataSource() -> DataSource {
        return DataSource(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, detailAttribute in
                let cell = tableView.dequeueReusableCell(withIdentifier: AttributeTableViewCell.reuseIdentifier, for: indexPath) as! AttributeTableViewCell
                
                cell.leftLabel.text = detailAttribute.titleKey
                cell.rightLabel.text = detailAttribute.titleValue
                
                return cell
            }
        )
    }
    private func applySnapshot(animatingDifferences: Bool = false) {
        sections = [
            Section(title: "Section 1", detailAttributes: [
                DetailAttribute(
                    titleKey: "Account Balance",
                    titleValue: account.attributes.balance.valueLong
                ),
                DetailAttribute(
                    titleKey: "Latest Transaction",
                    titleValue: transaction?.attributes.description ?? ""
                ),
                DetailAttribute(
                    titleKey: "Account ID",
                    titleValue: account.id
                ),
                DetailAttribute(
                    titleKey: "Creation Date",
                    titleValue: account.attributes.creationDate
                )
            ])
        ]
        
        var snapshot = Snapshot()
        
        snapshot.appendSections(sections)
        
        sections.forEach { section in
            snapshot.appendItems(section.detailAttributes.filter { detailAttribute in
                detailAttribute.titleValue != ""
            }, toSection: section)
        }
        
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
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
    
    override func viewWillAppear(_ animated: Bool) {
        applySnapshot()
    }
    
    private func setProperties() {
        title = "Account Details"
    }
    
    private func setupNavigation() {
        navigationItem.title = account.attributes.displayName
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func setupTableView() {
        tableView.dataSource = dataSource
        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: AttributeTableViewCell.reuseIdentifier)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let copy = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
            UIPasteboard.general.string = self.dataSource.itemIdentifier(for: indexPath)!.titleValue
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [copy])
        }
    }
}
