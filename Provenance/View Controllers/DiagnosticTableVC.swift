import UIKit
import Rswift

class DiagnosticTableVC: TableViewController {
    // MARK: - Properties

    private typealias DataSource = UITableViewDiffableDataSource<Section, DetailAttribute>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, DetailAttribute>

    private lazy var dataSource = makeDataSource()
    private lazy var sections: [Section] = [
        Section(title: "Section 1", detailAttributes: [
            DetailAttribute(
                key: "Version",
                value: appDefaults.appVersion
            ),
            DetailAttribute(
                key: "Build",
                value: appDefaults.appBuild
            )
        ])
    ]
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureProperties()
        configureNavigation()
        configureTableView()
        applySnapshot()
    }
}

// MARK: - Configuration

private extension DiagnosticTableVC {
    private func configureProperties() {
        title = "Diagnostics"
    }
    
    private func configureNavigation() {
        navigationItem.title = "Diagnostics"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func configureTableView() {
        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: AttributeTableViewCell.reuseIdentifier)
    }
}

// MARK: - Actions

private extension DiagnosticTableVC {
    @objc private func closeWorkflow() {
        navigationController?.dismiss(animated: true)
    }

    private func makeDataSource() -> DataSource {
        return DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, attribute in
                let cell = tableView.dequeueReusableCell(withIdentifier: AttributeTableViewCell.reuseIdentifier, for: indexPath) as! AttributeTableViewCell
                cell.leftLabel.text = attribute.key
                cell.rightLabel.text = attribute.value
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
}

// MARK: - UITableViewDelegate

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
