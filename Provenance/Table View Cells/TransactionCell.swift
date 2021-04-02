import UIKit
import TinyConstraints
import Rswift

class TransactionCell: UITableViewCell {
    var transaction: TransactionResource! {
        didSet {
            transactionDescription.text = transaction.attributes.description
            transactionCreationDate.text = transaction.attributes.creationDate
            
            if transaction.attributes.amount.valueInBaseUnits.signum() == -1 {
                transactionAmount.textColor = .black
            } else {
                transactionAmount.textColor = R.color.greenColour()
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
        
        configureCell()
        configureContentView()
        configureTransactionDescription()
        configureTransactionCreationDate()
        configureTransactionAmount()
        configureVerticalStackView()
        configureHorizontalStackView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension TransactionCell {
    private func configureCell() {
        selectionStyle = .default
        accessoryType = .none
        separatorInset = .zero
        selectedBackgroundView = bgCellView
    }
    
    private func configureContentView() {
        contentView.addSubview(horizontalStack)
    }
    
    private func configureTransactionDescription() {
        transactionDescription.translatesAutoresizingMaskIntoConstraints = false
        
        transactionDescription.font = R.font.circularStdBold(size: UIFont.labelFontSize)
        transactionDescription.textAlignment = .left
        transactionDescription.numberOfLines = 0
        transactionDescription.textColor = .black
    }
    
    private func configureTransactionCreationDate() {
        transactionCreationDate.translatesAutoresizingMaskIntoConstraints = false
        
        transactionCreationDate.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
        transactionCreationDate.textAlignment = .left
        transactionCreationDate.numberOfLines = 0
        transactionCreationDate.textColor = .darkGray
    }
    
    private func configureTransactionAmount() {
        transactionAmount.translatesAutoresizingMaskIntoConstraints = false
        
        transactionAmount.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        transactionAmount.textAlignment = .right
        transactionAmount.numberOfLines = 0
    }
    
    private func configureVerticalStackView() {
        verticalStack.addArrangedSubview(transactionDescription)
        verticalStack.addArrangedSubview(transactionCreationDate)
        
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        
        verticalStack.axis = .vertical
        verticalStack.alignment = .leading
        verticalStack.distribution = .fill
    }
    
    private func configureHorizontalStackView() {
        horizontalStack.addArrangedSubview(verticalStack)
        horizontalStack.addArrangedSubview(transactionAmount)
        
        horizontalStack.edges(to: contentView, insets: .horizontal(16) + .vertical(13))
        
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
    }
}
