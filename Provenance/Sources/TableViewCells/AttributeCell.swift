import UIKit
import SnapKit

final class AttributeCell: UITableViewCell {
    // MARK: - Properties
  
  static let reuseIdentifier = "attributeCell"
  
  var leftLabel = UILabel()
  var rightLabel = SRCopyableLabel()
  
  private let horizontalStack = UIStackView()
  
    // MARK: - Life Cycle
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    configureCell()
    configureContentView()
    configureLeftLabel()
    configureRightLabel()
    configureHorizontalStackView()
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }
}

  // MARK: - Configuration

private extension AttributeCell {
  private func configureCell() {
    separatorInset = .zero
    selectionStyle = .none
  }
  
  private func configureContentView() {
    contentView.addSubview(horizontalStack)
  }
  
  private func configureLeftLabel() {
    leftLabel.font = .circularStdMedium(size: UIFont.labelFontSize)
    leftLabel.textAlignment = .left
    leftLabel.textColor = .label
    leftLabel.numberOfLines = 0
  }
  
  private func configureRightLabel() {
    rightLabel.font = .circularStdBook(size: UIFont.labelFontSize)
    rightLabel.textAlignment = .right
    rightLabel.textColor = .secondaryLabel
    rightLabel.numberOfLines = 0
  }
  
  private func configureHorizontalStackView() {
    horizontalStack.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(UIEdgeInsets.cellNode)
    }
    horizontalStack.addArrangedSubview(leftLabel)
    horizontalStack.addArrangedSubview(rightLabel)
    horizontalStack.alignment = .center
    horizontalStack.distribution = .equalSpacing
  }
}
