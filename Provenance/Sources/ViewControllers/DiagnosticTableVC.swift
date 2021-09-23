import UIKit

final class DiagnosticTableVC: ViewController {
    // MARK: - Properties
  
  private typealias DataSource = UITableViewDiffableDataSource<DetailSection, DetailItem>
  
  private typealias Snapshot = NSDiffableDataSourceSnapshot<DetailSection, DetailItem>
  
  private lazy var dataSource = makeDataSource()
  
  private let tableView = UITableView(frame: .zero, style: .grouped)
  
  private var sections: [DetailSection] {
    return .diagnosticsSections
  }
  
    // MARK: - Life Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(tableView)
    configureSelf()
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
  private func configureSelf() {
    title = "Diagnostics"
  }
  
  private func configureNavigation() {
    navigationItem.title = "Diagnostics"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.leftBarButtonItem = .close(self, action: #selector(closeWorkflow))
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
        cell.text = attribute.id
        cell.detailText = attribute.value
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
    guard let attribute = dataSource.itemIdentifier(for: indexPath), attribute.value != "Unknown" else { return nil }
    return UIContextMenuConfiguration(elements: [
      .copyAttribute(attribute: attribute)
    ])
  }
}
