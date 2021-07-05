import UIKit
import TinyConstraints
import Rswift

final class TransactionCollectionViewCell: UICollectionViewCell {
    // MARK: - Properties

    static let reuseIdentifier = "transactionCollectionViewCell"

    var transaction: TransactionResource! {
        didSet {
            transactionDescription.text = transaction.attributes.description
            transactionCreationDate.text = transaction.attributes.creationDate
            transactionAmount.textColor = transaction.attributes.amount.valueInBaseUnits.signum() == -1 ? .label : R.color.greenColour()
            transactionAmount.text = transaction.attributes.amount.valueShort
        }
    }

    private let transactionDescription = UILabel()
    private let transactionCreationDate = UILabel()
    private let transactionAmount = UILabel()
    private let verticalStack = UIStackView()
    private let horizontalStack = UIStackView()
    private let insets: UIEdgeInsets = .zero
    private let separator: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.separator.cgColor
        return layer
    }()

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        
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

        horizontalStack.frame = contentView.bounds.inset(by: insets)
        separator.frame = CGRect(x: insets.left, y: contentView.bounds.height - 0.5, width: contentView.bounds.width - insets.left, height: 0.5)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        separator.backgroundColor = UIColor.separator.cgColor
    }
}

// MARK: - Configuration

private extension TransactionCollectionViewCell {
    private func configureCell() {
        backgroundColor = .clear
        selectedBackgroundView = selectedBackgroundCellView
    }

    private func configureContentView() {
        contentView.addSubview(horizontalStack)
        contentView.layer.addSublayer(separator)
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
