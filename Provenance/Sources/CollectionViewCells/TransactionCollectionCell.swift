import SnapKit
import IGListKit

final class TransactionCollectionCell: UICollectionViewCell {
    // MARK: - Properties
  
  private let transactionDescriptionLabel = UILabel()
  private let transactionCreationDateLabel = UILabel()
  private let transactionAmountLabel = UILabel()
  private let verticalStack = UIStackView()
  private let horizontalStack = UIStackView()
  private let separator = CALayer.separator
  
  private(set) var transactionDescription: String? {
    get {
      return transactionDescriptionLabel.text
    }
    set {
      transactionDescriptionLabel.text = newValue
    }
  }
  
  private(set) var transactionCreationDate: String? {
    get {
      return transactionCreationDateLabel.text
    }
    set {
      transactionCreationDateLabel.text = newValue
    }
  }
  
  private(set) var transactionAmount: String? {
    get {
      return transactionAmountLabel.text
    }
    set {
      transactionAmountLabel.text = newValue
    }
  }
  
  private(set) var transactionAmountColour: UIColor? {
    get {
      return transactionAmountLabel.textColor
    }
    set {
      transactionAmountLabel.textColor = newValue
    }
  }
  
    // MARK: - Life Cycle
  
  override func layoutSubviews() {
    super.layoutSubviews()
    horizontalStack.frame = contentView.bounds
    separator.frame = CGRect(x: 0, y: contentView.bounds.height - 0.5, width: contentView.bounds.width, height: 0.5)
  }
  
  override var isSelected: Bool {
    didSet {
      contentView.backgroundColor = isSelected ? .gray.withAlphaComponent(0.3) : .clear
    }
  }
  
  override var isHighlighted: Bool {
    didSet {
      contentView.backgroundColor = isHighlighted ? .gray.withAlphaComponent(0.3) : .clear
    }
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    separator.backgroundColor = .separator
  }
}

  // MARK: - Configuration

extension TransactionCollectionCell {
  private func configureContentView() {
    contentView.addSubview(horizontalStack)
    contentView.layer.addSublayer(separator)
  }
  
  private func configureTransactionDescription() {
    transactionDescriptionLabel.font = .circularStdBold(size: .labelFontSize)
    transactionDescriptionLabel.textAlignment = .left
    transactionDescriptionLabel.numberOfLines = 0
  }
  
  private func configureTransactionCreationDate() {
    transactionCreationDateLabel.font = .circularStdBookItalic(size: .smallSystemFontSize)
    transactionCreationDateLabel.textAlignment = .left
    transactionCreationDateLabel.numberOfLines = 0
    transactionCreationDateLabel.textColor = .secondaryLabel
  }
  
  private func configureTransactionAmount() {
    transactionAmountLabel.font = .circularStdBook(size: .labelFontSize)
    transactionAmountLabel.textAlignment = .right
    transactionAmountLabel.numberOfLines = 0
  }
  
  private func configureVerticalStackView() {
    verticalStack.addArrangedSubview(transactionDescriptionLabel)
    verticalStack.addArrangedSubview(transactionCreationDateLabel)
    verticalStack.axis = .vertical
    verticalStack.alignment = .leading
  }
  
  private func configureHorizontalStackView() {
    horizontalStack.snp.makeConstraints { (make) in
      make.edges.equalToSuperview().inset(UIEdgeInsets.cellNode)
    }
    horizontalStack.addArrangedSubview(verticalStack)
    horizontalStack.addArrangedSubview(transactionAmountLabel)
    horizontalStack.alignment = .center
    horizontalStack.distribution = .equalSpacing
  }
}

  // MARK: - ListBindable

extension TransactionCollectionCell: ListBindable {
  func bindViewModel(_ viewModel: Any) {
    guard let viewModel = viewModel as? TransactionCellModel else { return }
    configureContentView()
    configureTransactionDescription()
    configureTransactionCreationDate()
    configureTransactionAmount()
    configureVerticalStackView()
    configureHorizontalStackView()
    transactionDescription = viewModel.transactionDescription
    transactionCreationDate = viewModel.creationDate
    transactionAmount = viewModel.amount
    transactionAmountColour = viewModel.colour.uiColour
  }
}
