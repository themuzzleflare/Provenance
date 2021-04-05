import UIKit
import Rswift

class DiagnosticTableVC: TableViewController {
    private typealias DataSource = UITableViewDiffableDataSource<Section, DetailAttribute>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, DetailAttribute>
    
    private lazy var sections: [Section] = [
        Section(title: "Section 1", detailAttributes: [
            DetailAttribute(
                titleKey: "Version",
                titleValue: appVersion
            ),
            DetailAttribute(
                titleKey: "Build",
                titleValue: appBuild
            )
        ])
    ]
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
        var snapshot = Snapshot()
        
        snapshot.appendSections(sections)
        
        sections.forEach { section in
            snapshot.appendItems(section.detailAttributes, toSection: section)
        }
        
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigation()
        setupTableView()
        
        applySnapshot()
    }
}

extension DiagnosticTableVC {
    @objc private func closeWorkflow() {
        dismiss(animated: true)
    }
    
    private func setProperties() {
        title = "Diagnostics"
    }
    
    private func setupNavigation() {
        navigationItem.title = "Diagnostics"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func setupTableView() {
        tableView.dataSource = dataSource
        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: AttributeTableViewCell.reuseIdentifier)
    }
}

extension DiagnosticTableVC {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let attribute = dataSource.itemIdentifier(for: indexPath)!
        
        if attribute.titleValue != "Unknown" {
            let copy = UIAction(title: "Copy \(attribute.titleKey)", image: R.image.docOnClipboard()) { _ in
                UIPasteboard.general.string = attribute.titleValue
            }
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                UIMenu(children: [copy])
            }
        } else {
            return nil
        }
    }
}
