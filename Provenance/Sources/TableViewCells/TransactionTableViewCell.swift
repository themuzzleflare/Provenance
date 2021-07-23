import UIKit
import TinyConstraints
import Rswift

final class TransactionTableViewCell: UITableViewCell {
    // MARK: - Properties

    static let reuseIdentifier = "transactionTableViewCell"

    var transaction: TransactionResource! {
        didSet {
            transactionDescription.text = transaction.attributes.transactionDescription
            transactionCreationDate.text = transaction.attributes.creationDate
            transactionAmount.textColor = transaction.attributes.amount.valueInBaseUnits.signum() == -1
                ? .label : R.color.greenColour()
            transactionAmount.text = transaction.attributes.amount.valueShort
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
        configureCell()
        configureContentView()
        configureTransactionDescription()
        configureTransactionCreationDate()
        configureTransactionAmount()
        configureVerticalStackView()
        configureHorizontalStackView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        horizontalStack.frame = contentView.bounds
    }
}

// MARK: - Configuration

private extension TransactionTableViewCell {
    private func configureCell() {
        selectedBackgroundView = selectedBackgroundCellView
    }

    private func configureContentView() {
        contentView.addSubview(horizontalStack)
    }

    private func configureTransactionDescription() {
        transactionDescription.translatesAutoresizingMaskIntoConstraints = false
        transactionDescription.font = R.font.circularStdBold(size: UIFont.labelFontSize)
        transactionDescription.textAlignment = .left
        transactionDescription.numberOfLines = 0
    }

    private func configureTransactionCreationDate() {
        transactionCreationDate.translatesAutoresizingMaskIntoConstraints = false
        transactionCreationDate.font = R.font.circularStdBookItalic(size: UIFont.smallSystemFontSize)
        transactionCreationDate.textAlignment = .left
        transactionCreationDate.numberOfLines = 0
        transactionCreationDate.textColor = .secondaryLabel
    }

    private func configureTransactionAmount() {
        transactionAmount.translatesAutoresizingMaskIntoConstraints = false
        transactionAmount.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        transactionAmount.textAlignment = .right
        transactionAmount.numberOfLines = 0
    }

    private func configureVerticalStackView() {
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        verticalStack.addArrangedSubview(transactionDescription)
        verticalStack.addArrangedSubview(transactionCreationDate)
        verticalStack.axis = .vertical
        verticalStack.alignment = .leading
    }

    private func configureHorizontalStackView() {
        horizontalStack.edgesToSuperview(insets: .horizontal(16) + .vertical(13))
        horizontalStack.addArrangedSubview(verticalStack)
        horizontalStack.addArrangedSubview(transactionAmount)
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
    }
}
