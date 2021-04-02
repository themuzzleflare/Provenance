import UIKit
import MarqueeLabel
import TinyConstraints
import Rswift

class APIKeyCell: UITableViewCell {
    static let reuseIdentifier = "apiKeyCell"
    
    let apiKeyLabel = MarqueeLabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureCell()
        configureContentView()
        configureApiKeyLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension APIKeyCell {
    private func configureCell() {
        selectionStyle = .default
        accessoryType = .disclosureIndicator
        separatorInset = .zero
        selectedBackgroundView = bgCellView
    }
    
    private func configureContentView() {
        contentView.addSubview(apiKeyLabel)
    }
    
    private func configureApiKeyLabel() {
        apiKeyLabel.edges(to: contentView, insets: .horizontal(16) + .vertical(13))
        
        apiKeyLabel.speed = .rate(65)
        apiKeyLabel.fadeLength = 20
        
        apiKeyLabel.textAlignment = .left
        apiKeyLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        apiKeyLabel.textColor = .black
    }
}
