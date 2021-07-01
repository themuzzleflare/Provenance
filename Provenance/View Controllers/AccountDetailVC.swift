import UIKit
import Rswift

final class AccountDetailVC: UIViewController {
    // MARK: - Properties

    var account: AccountResource!
    var transaction: TransactionResource?
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, DetailAttribute>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, DetailAttribute>

    private lazy var dataSource = makeDataSource()

    private let tableView = UITableView(frame: .zero, style: .grouped)

    private var dateStyleObserver: NSKeyValueObservation?
    private var sections: [Section]!

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)

        configureProperties()
        configureNavigation()
        configureTableView()
        
        applySnapshot()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.frame = view.bounds
    }
}

// MARK: - Configuration

private extension AccountDetailVC {
    private func configureProperties() {
        title = "Account Details"

        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { [self] object, change in
            applySnapshot()
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = account.attributes.displayName
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func configureTableView() {
        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: AttributeTableViewCell.reuseIdentifier)
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}

// MARK: - Actions

private extension AccountDetailVC {
    @objc private func closeWorkflow() {
        navigationController?.dismiss(animated: true)
    }

    private func makeDataSource() -> DataSource {
        DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, attribute in
                let cell = tableView.dequeueReusableCell(withIdentifier: AttributeTableViewCell.reuseIdentifier, for: indexPath) as! AttributeTableViewCell

                cell.leftLabel.text = attribute.key
                cell.rightLabel.font = attribute.key == "Account ID" ? R.font.sfMonoRegular(size: UIFont.labelFontSize)! : R.font.circularStdBook(size: UIFont.labelFontSize)!
                cell.rightLabel.text = attribute.value

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
            snapshot.appendItems(section.detailAttributes.filter { attribute in
                !attribute.value.isEmpty
            }, toSection: section)
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - UITableViewDelegate

extension AccountDetailVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let attribute = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy \(attribute.key)", image: R.image.docOnClipboard()) { _ in
                    UIPasteboard.general.string = attribute.value
                }
            ])
        }
    }
}
