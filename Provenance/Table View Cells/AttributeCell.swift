import UIKit

class AttributeCell: UITableViewCell {
    static let reuseIdentifier = "attributeCell"
    
    let leftLabel = UILabel()
    let rightLabel = UILabel()
    let horizontalStack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupCell()
        setupContentView()
        setupLeftLabel()
        setupRightLabel()
        setupHorizontalStackView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension AttributeCell {
    private func setupCell() {
        selectionStyle = .none
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
    
    private func setupLeftLabel() {
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        
        leftLabel.font = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)
        leftLabel.textAlignment = .left
        leftLabel.textColor = .darkGray
        leftLabel.numberOfLines = 0
    }
    
    private func setupRightLabel() {
        rightLabel.translatesAutoresizingMaskIntoConstraints = false
        
        rightLabel.font = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)
        rightLabel.textAlignment = .right
        rightLabel.textColor = .black
        rightLabel.numberOfLines = 0
    }
    
    private func setupHorizontalStackView() {
        horizontalStack.addArrangedSubview(leftLabel)
        horizontalStack.addArrangedSubview(rightLabel)
        
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16).isActive = true
        horizontalStack.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16).isActive = true
        
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
    }
}
