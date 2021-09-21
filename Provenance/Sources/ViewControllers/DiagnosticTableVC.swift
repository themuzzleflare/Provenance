import UIKit

final class DiagnosticTableVC: ViewController {
    // MARK: - Properties
  
  private typealias DataSource = UITableViewDiffableDataSource<DetailSection, DetailItem>
  
  private typealias Snapshot = NSDiffableDataSourceSnapshot<DetailSection, DetailItem>
  
  private lazy var dataSource = makeDataSource()
  
  private lazy var sections: [DetailSection] = [
    DetailSection(id: 1, items: [
      DetailItem(
        id: "Version",
        value: appDefaults.appVersion
      ),
      DetailItem(
        id: "Build",
        value: appDefaults.appBuild
      )
    ])
  ]
  
  private let tableView = UITableView(frame: .zero, style: .grouped)
  
    // MARK: - Life Cycle
  
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

private extension DiagnosticTableVC {
  private func configureProperties() {
    title = "Diagnostics"
  }
  
  private func configureNavigation() {
    navigationItem.title = "Diagnostics"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
  }
  
  private func configureTableView() {
    tableView.dataSource = dataSource
    tableView.delegate = self
    tableView.register(AttributeCell.self, forCellReuseIdentifier: AttributeCell.reuseIdentifier)
    tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    tableView.showsVerticalScrollIndicator = false
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AttributeCell.reuseIdentifier, for: indexPath) as? AttributeCell else {
          fatalError("Unable to dequeue reusable cell with identifier: \(AttributeCell.reuseIdentifier)")
        }
        cell.leftLabel.text = attribute.id
        cell.rightLabel.text = attribute.value
        return cell
      }
    )
  }
  
  private func applySnapshot(animate: Bool = false) {
    var snapshot = Snapshot()
    snapshot.appendSections(sections)
    sections.forEach { snapshot.appendItems($0.items, toSection: $0) }
    dataSource.apply(snapshot, animatingDifferences: animate)
  }
}

  // MARK: - UITableViewDelegate

extension DiagnosticTableVC: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }
  
  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    guard let attribute = dataSource.itemIdentifier(for: indexPath) else {
      return nil
    }
    switch attribute.id {
    case "Unknown":
      return nil
    default:
      return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (_) in
        UIMenu(children: [
          UIAction(title: "Copy \(attribute.id)", image: .docOnClipboard) { (_) in
            UIPasteboard.general.string = attribute.value
          }
        ])
      }
    }
  }
}
