import UIKit
import TinyConstraints
import Rswift

class AttributeTableViewCell: UITableViewCell {
    static let reuseIdentifier = "attributeTableViewCell"
    
    let leftLabel = UILabel()
    let rightLabel = UILabel()
    let horizontalStack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureCell()
        configureContentView()
        configureLeftLabel()
        configureRightLabel()
        configureHorizontalStackView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AttributeTableViewCell {
    private func configureCell() {
        selectionStyle = .none
        accessoryType = .none
        separatorInset = .zero
        selectedBackgroundView = bgCellView
    }
    
    private func configureContentView() {
        contentView.addSubview(horizontalStack)
    }
    
    private func configureLeftLabel() {
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        
        leftLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        leftLabel.textAlignment = .left
        leftLabel.textColor = .darkGray
        leftLabel.numberOfLines = 0
    }
    
    private func configureRightLabel() {
        rightLabel.translatesAutoresizingMaskIntoConstraints = false
        
        rightLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        rightLabel.textAlignment = .right
        rightLabel.textColor = .black
        rightLabel.numberOfLines = 0
    }
    
    private func configureHorizontalStackView() {
        horizontalStack.addArrangedSubview(leftLabel)
        horizontalStack.addArrangedSubview(rightLabel)
        
        horizontalStack.edges(to: contentView, insets: .horizontal(16) + .vertical(13))
        
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
    }
}
