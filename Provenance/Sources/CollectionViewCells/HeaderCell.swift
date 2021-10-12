import UIKit
import IGListKit
import SwiftDate

final class HeaderCell: UICollectionViewCell {
  private let dateLabel = UILabel()
  
  private(set) var dateText: String? {
    get {
      return dateLabel.text
    }
    set {
      dateLabel.text = newValue
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    dateLabel.frame = contentView.bounds.inset(by: .sectionHeader)
  }
  
  private func configure() {
    contentView.addSubview(dateLabel)
    contentView.backgroundColor = .secondarySystemGroupedBackground
    dateLabel.font = .circularStdBook(size: .labelFontSize)
  }
}

// MARK: - ListBindable

extension HeaderCell: ListBindable {
  func bindViewModel(_ viewModel: Any) {
    guard let viewModel = viewModel as? SortedSectionModel else { return }
    configure()
    dateText = viewModel.id.toString(.date(.medium))
  }
}
