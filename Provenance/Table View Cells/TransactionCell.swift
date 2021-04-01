import UIKit

class TransactionCell: UITableViewCell {
    var transaction: TransactionResource! {
        didSet {
            transactionDescription.text = transaction.attributes.description
            transactionCreationDate.text = transaction.attributes.creationDate
            
            if transaction.attributes.amount.valueInBaseUnits.signum() == -1 {
                transactionAmount.textColor = .black
            } else {
                transactionAmount.textColor = UIColor(named: "greenColour")
            }
            
            transactionAmount.text = transaction.attributes.amount.valueShort
        }
    }
    
    static let reuseIdentifier = "transactionCell"
    
    let transactionDescription = UILabel()
    let transactionCreationDate = UILabel()
    let transactionAmount = UILabel()
    let verticalStack = UIStackView()
    let horizontalStack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupCell()
        setupContentView()
        setupTransactionDescription()
        setupTransactionCreationDate()
        setupTransactionAmount()
        setupVerticalStackView()
        setupHorizontalStackView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension TransactionCell {
    private func setupCell() {
        selectionStyle = .default
        accessoryType = .none
        separatorInset = .zero
        selectedBackgroundView = {
            let view = UIView()
            view.backgroundColor = UIColor(named: "AccentColor")
            return view
        }()
    }
    
    private func setupContentView() {
        contentView.addSubview(horizontalStack)
        
        contentView.topAnchor.constraint(equalTo: horizontalStack.topAnchor, constant: -13).isActive = true
        contentView.bottomAnchor.constraint(equalTo: horizontalStack.bottomAnchor, constant: 13).isActive = true
    }
    
    private func setupTransactionDescription() {
        transactionDescription.translatesAutoresizingMaskIntoConstraints = false
        
        transactionDescription.font = UIFont(name: "CircularStd-Bold", size: UIFont.labelFontSize)
        transactionDescription.textAlignment = .left
        transactionDescription.numberOfLines = 0
        transactionDescription.textColor = .black
    }
    
    private func setupTransactionCreationDate() {
        transactionCreationDate.translatesAutoresizingMaskIntoConstraints = false
        
        transactionCreationDate.font = UIFont(name: "CircularStd-Book", size: UIFont.smallSystemFontSize)
        transactionCreationDate.textAlignment = .left
        transactionCreationDate.numberOfLines = 0
        transactionCreationDate.textColor = .darkGray
    }
    
    private func setupTransactionAmount() {
        transactionAmount.translatesAutoresizingMaskIntoConstraints = false
        
        transactionAmount.font = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)
        transactionAmount.textAlignment = .right
        transactionAmount.numberOfLines = 0
    }
    
    private func setupVerticalStackView() {
        verticalStack.addArrangedSubview(transactionDescription)
        verticalStack.addArrangedSubview(transactionCreationDate)
        
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        
        verticalStack.axis = .vertical
        verticalStack.alignment = .leading
        verticalStack.distribution = .fill
    }
    
    private func setupHorizontalStackView() {
        horizontalStack.addArrangedSubview(verticalStack)
        horizontalStack.addArrangedSubview(transactionAmount)
        
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16).isActive = true
        horizontalStack.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16).isActive = true
        
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
    }
}
