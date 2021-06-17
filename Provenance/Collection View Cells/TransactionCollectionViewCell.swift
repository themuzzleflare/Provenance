import UIKit
import TinyConstraints
import Rswift

class TransactionCollectionViewCell: UICollectionViewCell {
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

    private let separator: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.separator.cgColor
        return layer
    }()
    private let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    private let transactionDescription = UILabel()
    private let transactionCreationDate = UILabel()
    private let transactionAmount = UILabel()
    private let verticalStack = UIStackView()
    private let horizontalStack = UIStackView()

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
        let bounds = contentView.bounds
        horizontalStack.frame = bounds.inset(by: insets)
        let height: CGFloat = 0.5
        let left = insets.left
        separator.frame = CGRect(x: left, y: bounds.height - height, width: bounds.width - left, height: height)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        separator.backgroundColor = UIColor.separator.cgColor
    }
}

// MARK: - Configuration

private extension TransactionCollectionViewCell {
    private func configureCell() {
        selectedBackgroundView = selectedBackgroundCellView
    }

    private func configureContentView() {
        contentView.backgroundColor = .clear
        contentView.addSubview(horizontalStack)
        contentView.layer.addSublayer(separator)

        NSLayoutConstraint(item: horizontalStack,
                           attribute: .top,
                           relatedBy: .equal,
                           toItem: contentView,
                           attribute: .top,
                           multiplier: 1,
                           constant: 15).isActive = true
        NSLayoutConstraint(item: horizontalStack,
                           attribute: .leading,
                           relatedBy: .equal,
                           toItem: contentView,
                           attribute: .leading,
                           multiplier: 1,
                           constant: 15).isActive = true
        NSLayoutConstraint(item: contentView,
                           attribute: .bottom,
                           relatedBy: .equal,
                           toItem: horizontalStack,
                           attribute: .bottom,
                           multiplier: 1,
                           constant: 15).isActive = true
        NSLayoutConstraint(item: contentView,
                           attribute: .trailing,
                           relatedBy: .equal,
                           toItem: horizontalStack,
                           attribute: .trailing,
                           multiplier: 1,
                           constant: 15).isActive = true
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
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.addArrangedSubview(verticalStack)
        horizontalStack.addArrangedSubview(transactionAmount)
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
    }
}
