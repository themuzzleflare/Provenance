import UIKit
import MarqueeLabel
import TinyConstraints
import Rswift

final class APIKeyTableViewCell: UITableViewCell {
    // MARK: - Properties

    static let reuseIdentifier = "apiKeyTableViewCell"

    private let apiKeyLabel = MarqueeLabel()

    private var apiKeyObserver: NSKeyValueObservation?

    private var apiKeyDisplay: String {
        switch appDefaults.apiKey {
        case "": return "None"
        default: return appDefaults.apiKey
        }
    }

    // MARK: - Life Cycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(
            style: style,
            reuseIdentifier: reuseIdentifier
        )

        apiKeyObserver = appDefaults.observe(
            \.apiKey,
            options: .new,
            changeHandler: {
                [self] (_, _) in
                DispatchQueue.main.async {
                    apiKeyLabel.text = apiKeyDisplay
                    apiKeyLabel.textColor = apiKeyDisplay == "None"
                        ? .placeholderText
                        : .label
                }
            }
        )

        configureCell()
        configureContentView()
        configureApiKeyLabel()
    }

    required init?(coder: NSCoder) { fatalError("Not implemented") }
}

// MARK: - Configuration

private extension APIKeyTableViewCell {
    private func configureCell() {
        accessoryType = .disclosureIndicator
        selectedBackgroundView = selectedBackgroundCellView
    }

    private func configureContentView() {
        contentView.addSubview(apiKeyLabel)
    }

    private func configureApiKeyLabel() {
        apiKeyLabel.edgesToSuperview(insets: .horizontal(16) + .vertical(13))
        apiKeyLabel.speed = .rate(65)
        apiKeyLabel.fadeLength = 10
        apiKeyLabel.textAlignment = .left
        apiKeyLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)

        apiKeyLabel.textColor = apiKeyDisplay == "None"
            ? .placeholderText
            : .label

        apiKeyLabel.text = apiKeyDisplay
    }
}
