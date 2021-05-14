import UIKit
import WidgetKit
import MarqueeLabel
import TinyConstraints
import Rswift

class APIKeyTableViewCell: UITableViewCell {
    static let reuseIdentifier = "apiKeyTableViewCell"

    private var apiKeyObserver: NSKeyValueObservation?
    private var apiKeyDisplay: String {
        switch appDefaults.apiKey {
            case "":
                return "None"
            default:
                return appDefaults.apiKey
        }
    }
    
    private let apiKeyLabel = MarqueeLabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { object, change in
            self.apiKeyLabel.text = change.newValue
            WidgetCenter.shared.reloadAllTimelines()
        }
        configureCell()
        configureContentView()
        configureApiKeyLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

private extension APIKeyTableViewCell {
    private func configureCell() {
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
        apiKeyLabel.text = apiKeyDisplay
    }
}
