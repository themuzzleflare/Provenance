import IntentsUI
import SnapKit

final class TransactionCell: UITableViewCell {
    // MARK: - Properties
  
  static let reuseIdentifier = "transactionCell"
  
  private let transactionDescriptionLabel = UILabel()
  private let transactionCreationDateLabel = UILabel()
  private let transactionAmountLabel = UILabel()
  private let verticalStack = UIStackView()
  private let horizontalStack = UIStackView()
  
  var transaction: TransactionType! {
    didSet {
      transactionDescription = transaction.transactionDescription
      transactionCreationDate = transaction.transactionCreationDate
      transactionAmount = transaction.transactionAmount
      transactionAmountColour = transaction.transactionColour.uiColour
    }
  }
  
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
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    configureCell()
    configureContentView()
    configureTransactionDescription()
    configureTransactionCreationDate()
    configureTransactionAmount()
    configureVerticalStackView()
    configureHorizontalStackView()
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    horizontalStack.frame = contentView.bounds
  }
}

  // MARK: - Configuration

private extension TransactionCell {
  private func configureCell() {
    separatorInset = .zero
  }
  
  private func configureContentView() {
    contentView.addSubview(horizontalStack)
  }
  
  private func configureTransactionDescription() {
    transactionDescriptionLabel.font = .circularStdBold(size: UIFont.labelFontSize)
    transactionDescriptionLabel.textAlignment = .left
    transactionDescriptionLabel.numberOfLines = 0
  }
  
  private func configureTransactionCreationDate() {
    transactionCreationDateLabel.font = .circularStdBookItalic(size: UIFont.smallSystemFontSize)
    transactionCreationDateLabel.textAlignment = .left
    transactionCreationDateLabel.numberOfLines = 0
    transactionCreationDateLabel.textColor = .secondaryLabel
  }
  
  private func configureTransactionAmount() {
    transactionAmountLabel.font = .circularStdBook(size: UIFont.labelFontSize)
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
    horizontalStack.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(UIEdgeInsets.cellNode)
    }
    horizontalStack.addArrangedSubview(verticalStack)
    horizontalStack.addArrangedSubview(transactionAmountLabel)
    horizontalStack.alignment = .center
    horizontalStack.distribution = .equalSpacing
  }
}
