import UIKit
import Rswift

class DiagnosticTableVC: TableViewController {
    private typealias DataSource = UITableViewDiffableDataSource<Section, DetailAttribute>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, DetailAttribute>
    
    private lazy var sections: [Section] = [
        Section(title: "Section 1", detailAttributes: [
            DetailAttribute(
                key: "Version",
                value: appVersion
            ),
            DetailAttribute(
                key: "Build",
                value: appBuild
            )
        ])
    ]

    private lazy var dataSource = makeDataSource()
    
    private func makeDataSource() -> DataSource {
        return DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, detailAttribute in
                let cell = tableView.dequeueReusableCell(withIdentifier: AttributeTableViewCell.reuseIdentifier, for: indexPath) as! AttributeTableViewCell
                cell.leftLabel.text = detailAttribute.key
                cell.rightLabel.text = detailAttribute.value
                return cell
            }
        )
    }

    private func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections(sections)
        sections.forEach { section in
            snapshot.appendItems(section.detailAttributes, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureProperties()
        configureNavigation()
        configureTableView()
        applySnapshot()
    }
}

private extension DiagnosticTableVC {
    @objc private func closeWorkflow() {
        navigationController?.dismiss(animated: true)
    }
    
    private func configureProperties() {
        title = "Diagnostics"
    }
    
    private func configureNavigation() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "Diagnostics"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func configureTableView() {
        tableView.dataSource = dataSource
        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: AttributeTableViewCell.reuseIdentifier)
    }
}

extension DiagnosticTableVC {
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let attribute = dataSource.itemIdentifier(for: indexPath)!

        switch attribute.value {
            case "Unknown":
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
