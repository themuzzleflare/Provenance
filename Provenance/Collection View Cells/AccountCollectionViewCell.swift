import UIKit
import TinyConstraints
import Rswift

class AccountCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "accountCollectionViewCell"
    
    var account: AccountResource? {
        didSet {
            if let account = account {
                balanceLabel.text = account.attributes.balance.valueShort
                displayNameLabel.text = account.attributes.displayName
            } else {
                balanceLabel.text = "Balance"
                displayNameLabel.text = "Display Name"
            }
        }
    }
    
    let balanceLabel = UILabel()
    let displayNameLabel = UILabel()
    let verticalStack = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCell()
        configureContentView()
        configureBalanceLabel()
        configureDisplayNameLabel()
        configureStackView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

private extension AccountCollectionViewCell {
    private func configureCell() {
        clipsToBounds = true
        layer.cornerRadius = 12.5
        layer.borderColor = UIColor.separator.cgColor
        layer.borderWidth = 1
        backgroundColor = .secondarySystemGroupedBackground
        selectedBackgroundView = selectedBackgroundCellView
    }
    
    private func configureContentView() {
        contentView.addSubview(verticalStack)
    }
    
    private func configureBalanceLabel() {
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.textAlignment = .center
        balanceLabel.numberOfLines = 1
        balanceLabel.textColor = R.color.accentColour()
        balanceLabel.font = R.font.circularStdBold(size: 32)
    }
    
    private func configureDisplayNameLabel() {
        displayNameLabel.translatesAutoresizingMaskIntoConstraints = false
        displayNameLabel.textAlignment = .center
        displayNameLabel.numberOfLines = 1
        displayNameLabel.textColor = .label
        displayNameLabel.font = R.font.adobeCleanRegular(size: UIFont.labelFontSize)
    }
    
    private func configureStackView() {
        verticalStack.edges(to: contentView, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
        verticalStack.center(in: contentView)
        verticalStack.addArrangedSubview(balanceLabel)
        verticalStack.addArrangedSubview(displayNameLabel)
        verticalStack.axis = .vertical
        verticalStack.alignment = .center
        verticalStack.distribution = .fillProportionally
        verticalStack.spacing = 0
    }
}

extension AccountCollectionViewCell {
    override var isHighlighted: Bool {
        didSet {
            balanceLabel.textColor = isHighlighted ? .label : R.color.accentColour()
        }
    }

    override var isSelected: Bool {
        didSet {
            balanceLabel.textColor = isSelected ? .label : R.color.accentColour()
        }
    }
}
