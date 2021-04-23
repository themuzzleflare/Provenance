import UIKit
import MarqueeLabel
import TinyConstraints
import Rswift

class APIKeyTableViewCell: UITableViewCell {
    static let reuseIdentifier = "apiKeyTableViewCell"
    
    let apiKeyLabel = MarqueeLabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
        configureContentView()
        configureApiKeyLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

extension APIKeyTableViewCell {
    private func configureCell() {
        selectionStyle = .default
        accessoryType = .disclosureIndicator
        separatorInset = .zero
        selectedBackgroundView = selectedBackgroundCellView
    }
    
    private func configureContentView() {
        contentView.addSubview(apiKeyLabel)
    }
    
    private func configureApiKeyLabel() {
        apiKeyLabel.edges(to: contentView, insets: .horizontal(16) + .vertical(13))
        apiKeyLabel.speed = .rate(65)
        apiKeyLabel.fadeLength = 10
        apiKeyLabel.textAlignment = .left
        apiKeyLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        apiKeyLabel.textColor = .label
    }
}
