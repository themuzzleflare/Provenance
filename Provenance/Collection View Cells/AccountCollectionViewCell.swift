import UIKit
import TinyConstraints
import Rswift

class AccountCollectionViewCell: UICollectionViewCell {
    var account: AccountResource! {
        didSet {
            balanceLabel.text = account.attributes.balance.valueShort
            displayNameLabel.text = account.attributes.displayName
        }
    }
    
    static let reuseIdentifier = "accountCollectionViewCell"

    override var isHighlighted: Bool {
        didSet {
            balanceLabel.textColor = isHighlighted ? .label : R.color.accentColor()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            balanceLabel.textColor = isSelected ? .label : R.color.accentColor()
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
        fatalError("init(coder:) has not been implemented")
    }
}

extension AccountCollectionViewCell {
    private func configureCell() {
        clipsToBounds = true
        layer.cornerRadius = 12.5
        layer.borderColor = UIColor.separator.cgColor
        layer.borderWidth = 0.5
        backgroundColor = .secondarySystemGroupedBackground
        selectedBackgroundView = bgCellView
    }
    
    private func configureContentView() {
        contentView.addSubview(verticalStack)
    }
    
    private func configureBalanceLabel() {
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        balanceLabel.textAlignment = .center
        balanceLabel.numberOfLines = 0
        balanceLabel.textColor = R.color.accentColor()
        balanceLabel.font = R.font.circularStdBold(size: 32)
    }
    
    private func configureDisplayNameLabel() {
        displayNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        displayNameLabel.textAlignment = .center
        displayNameLabel.numberOfLines = 0
        displayNameLabel.textColor = .label
        displayNameLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
    }
    
    private func configureStackView() {
        verticalStack.addArrangedSubview(balanceLabel)
        verticalStack.addArrangedSubview(displayNameLabel)
        
        verticalStack.edges(to: contentView, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
        verticalStack.center(in: contentView)
        
        verticalStack.axis = .vertical
        verticalStack.alignment = .center
        verticalStack.distribution = .fillProportionally
    }
}
