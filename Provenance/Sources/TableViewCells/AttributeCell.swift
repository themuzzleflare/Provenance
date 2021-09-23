import SnapKit

final class AttributeCell: UITableViewCell {
    // MARK: - Properties
  
  static let reuseIdentifier = "attributeCell"
  
  private let leftLabel = UILabel()
  private let rightLabel = UILabel()
  private let horizontalStack = UIStackView()
  
  var text: String? {
    get {
      return leftLabel.text
    }
    set {
      leftLabel.text = newValue
    }
  }
  
  var detailText: String? {
    get {
      return rightLabel.text
    }
    set {
      rightLabel.text = newValue
    }
  }
  
  var detailFont: UIFont? {
    get {
      return rightLabel.font
    }
    set {
      rightLabel.font = newValue
    }
  }
  
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
    leftLabel.font = .circularStdMedium(size: .labelFontSize)
    leftLabel.textAlignment = .left
    leftLabel.textColor = .label
    leftLabel.numberOfLines = 0
  }
  
  private func configureRightLabel() {
    rightLabel.font = .circularStdBook(size: .labelFontSize)
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
