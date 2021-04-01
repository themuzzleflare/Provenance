import UIKit
import MarqueeLabel

class APIKeyCell: UITableViewCell {
    static let reuseIdentifier = "apiKeyCell"
    
    let apiKeyLabel = MarqueeLabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupCell()
        setupContentView()
        setupApiKeyLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension APIKeyCell {
    private func setupCell() {
        selectionStyle = .default
        accessoryType = .disclosureIndicator
        separatorInset = .zero
        selectedBackgroundView = {
            let view = UIView()
            view.backgroundColor = UIColor(named: "AccentColor")
            return view
        }()
    }
    
    private func setupContentView() {
        contentView.addSubview(apiKeyLabel)
    }
    
    private func setupApiKeyLabel() {
        apiKeyLabel.translatesAutoresizingMaskIntoConstraints = false
        apiKeyLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16).isActive = true
        apiKeyLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16).isActive = true
        apiKeyLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        apiKeyLabel.speed = .rate(65)
        apiKeyLabel.leadingBuffer = 20
        apiKeyLabel.fadeLength = 20
        
        apiKeyLabel.font = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)
        apiKeyLabel.textColor = .black
    }
}
