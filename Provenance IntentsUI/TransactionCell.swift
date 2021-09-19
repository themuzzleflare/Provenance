import UIKit
import IntentsUI
import SwiftDate
import SnapKit

final class TransactionCell: UITableViewCell {
  // MARK: - Properties

  static let reuseIdentifier = "transactionCell"

  var transaction: TransactionType! {
    didSet {
      transactionDescription.text = transaction.transactionDescription
      transactionCreationDate.text = transaction.transactionCreationDate
      transactionAmount.text = transaction.transactionAmount
    }
  }

  private let transactionDescription = UILabel()
  private let transactionCreationDate = UILabel()
  private let transactionAmount = UILabel()
  private let verticalStack = UIStackView()
  private let horizontalStack = UIStackView()

  // MARK: - Life Cycle

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
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
  private func configureContentView() {
    separatorInset = .zero
    contentView.addSubview(horizontalStack)
  }

  private func configureTransactionDescription() {
    transactionDescription.font = .circularStdBold(size: UIFont.labelFontSize)
    transactionDescription.textAlignment = .left
    transactionDescription.numberOfLines = 0
  }

  private func configureTransactionCreationDate() {
    transactionCreationDate.font = .circularStdBookItalic(size: UIFont.smallSystemFontSize)
    transactionCreationDate.textAlignment = .left
    transactionCreationDate.numberOfLines = 0
    transactionCreationDate.textColor = .secondaryLabel
  }

  private func configureTransactionAmount() {
    transactionAmount.font = .circularStdBook(size: UIFont.labelFontSize)
    transactionAmount.textAlignment = .right
    transactionAmount.numberOfLines = 0
  }

  private func configureVerticalStackView() {
    verticalStack.addArrangedSubview(transactionDescription)
    verticalStack.addArrangedSubview(transactionCreationDate)
    verticalStack.axis = .vertical
    verticalStack.alignment = .leading
  }

  private func configureHorizontalStackView() {
    horizontalStack.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(UIEdgeInsets.cellNode)
    }
    horizontalStack.addArrangedSubview(verticalStack)
    horizontalStack.addArrangedSubview(transactionAmount)
    horizontalStack.alignment = .center
    horizontalStack.distribution = .equalSpacing
  }
}
