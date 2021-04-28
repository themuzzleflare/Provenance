import UIKit
import TinyConstraints
import Rswift

class TransactionTableViewCell: UITableViewCell {
    static let reuseIdentifier = "transactionTableViewCell"
    
    var transaction: TransactionResource? {
        didSet {
            if let transaction = transaction {
                transactionDescription.text = transaction.attributes.description
                transactionCreationDate.text = transaction.attributes.creationDate
                transactionAmount.textColor = transaction.attributes.amount.valueInBaseUnits.signum() == -1 ? .label : R.color.greenColour()
                transactionAmount.text = transaction.attributes.amount.valueShort
            } else {
                transactionDescription.text = "Description"
                transactionCreationDate.text = "Creation Date"
                transactionAmount.textColor = .label
                transactionAmount.text = "Amount"
            }
        }
    }
    
    let transactionDescription = UILabel()
    let transactionCreationDate = UILabel()
    let transactionAmount = UILabel()
    let verticalStack = UIStackView()
    let horizontalStack = UIStackView()
    
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
}

private extension TransactionTableViewCell {
    private func configureCell() {
        selectionStyle = .default
        accessoryType = .none
        separatorInset = .zero
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
        transactionDescription.textColor = .label
    }
    
    private func configureTransactionCreationDate() {
        transactionCreationDate.translatesAutoresizingMaskIntoConstraints = false
        transactionCreationDate.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
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
        verticalStack.distribution = .fill
    }
    
    private func configureHorizontalStackView() {
        horizontalStack.edges(to: contentView, insets: .horizontal(16) + .vertical(13))
        horizontalStack.addArrangedSubview(verticalStack)
        horizontalStack.addArrangedSubview(transactionAmount)
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
    }
}
