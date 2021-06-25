import UIKit
import FLAnimatedImage
import TinyConstraints
import Rswift

class AboutTopTableViewCell: UITableViewCell {
    // MARK: - Properties

    static let reuseIdentifier = "aboutTopTableViewCell"

    private let logoImageView = FLAnimatedImageView()
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let verticalStack = UIStackView()

    // MARK: - Life Cycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

// MARK: - Configuration

private extension AboutTopTableViewCell {
    private func configure() {
        selectionStyle = .none
        separatorInset = .zero
        contentView.addSubview(verticalStack)
        verticalStack.edges(to: contentView, insets: .horizontal(16) + .vertical(13))
        verticalStack.addArrangedSubview(logoImageView)
        verticalStack.addArrangedSubview(nameLabel)
        verticalStack.addArrangedSubview(descriptionLabel)
        verticalStack.axis = .vertical
        verticalStack.alignment = .center
        verticalStack.spacing = 5
        logoImageView.clipsToBounds = true
        logoImageView.width(100)
        logoImageView.height(100)
        logoImageView.layer.cornerRadius = 20
        logoImageView.backgroundColor = R.color.accentColour()
        logoImageView.animatedImage = upLogoDrawMidnightYellowTransparentBackground
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = R.font.circularStdBold(size: 32)
        nameLabel.textAlignment = .center
        nameLabel.text = appName
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        descriptionLabel.textAlignment = .left
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = "Provenance is a lightweight application that interacts with the Up Banking Developer API to display information about your bank accounts, transactions, categories, tags, and more."
    }
}
