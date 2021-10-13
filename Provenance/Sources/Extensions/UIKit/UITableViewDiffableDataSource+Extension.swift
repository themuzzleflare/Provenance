import UIKit

extension UITableViewDiffableDataSource {
  convenience init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>.CellProvider, defaultRowAnimation: UITableView.RowAnimation) {
    self.init(tableView: tableView, cellProvider: cellProvider)
    self.defaultRowAnimation = defaultRowAnimation
  }
}
