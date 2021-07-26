import UIKit
import TinyConstraints
import Rswift

final class AccountCollectionViewCell: UICollectionViewCell {
    // MARK: - Properties

    static let reuseIdentifier = "accountCollectionViewCell"

    var account: AccountResource! {
        didSet {
            balanceLabel.text = account.attributes.balance.valueShort
            displayNameLabel.text = account.attributes.displayName
        }
    }

    private let balanceLabel = UILabel()
    private let displayNameLabel = UILabel()

    private let verticalStack = UIStackView()

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureCell()
        configureContentView()
        configureBalanceLabel()
        configureDisplayNameLabel()
        configureStackView()
    }

    required init?(coder: NSCoder) { fatalError("Not implemented") }

    override var isHighlighted: Bool {
        didSet {
            balanceLabel.textColor = isHighlighted
                ? .label
                : R.color.accentColor()
        }
    }

    override var isSelected: Bool {
        didSet {
            balanceLabel.textColor = isSelected
                ? .label
                : R.color.accentColor()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        layer.borderColor = UIColor.separator.cgColor
    }
}

// MARK: - Configuration

private extension AccountCollectionViewCell {
    private func configureCell() {
        clipsToBounds = true

        layer.cornerRadius = 12.5

        layer.borderColor = UIColor.separator.cgColor

        layer.borderWidth = 1.0

        backgroundColor = .secondarySystemGroupedBackground

        selectedBackgroundView = selectedBackgroundCellView
    }

    private func configureContentView() {
        contentView.addSubview(verticalStack)
    }

    private func configureBalanceLabel() {
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false

        balanceLabel.textAlignment = .center

        balanceLabel.textColor = R.color.accentColor()

        balanceLabel.font = R.font.circularStdBold(size: 32)
    }

    private func configureDisplayNameLabel() {
        displayNameLabel.translatesAutoresizingMaskIntoConstraints = false

        displayNameLabel.textAlignment = .center

        displayNameLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
    }

    private func configureStackView() {
        verticalStack.horizontalToSuperview(insets: .horizontal(16))

        verticalStack.centerInSuperview()

        verticalStack.addArrangedSubview(balanceLabel)

        verticalStack.addArrangedSubview(displayNameLabel)

        verticalStack.axis = .vertical

        verticalStack.alignment = .center
    }
}
