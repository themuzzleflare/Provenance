import UIKit
import TinyConstraints
import Rswift

class AboutTopTableViewCell: UITableViewCell {
    static let reuseIdentifier = "aboutTopTableViewCell"

    let logoImageView = UIImageView()
    let nameLabel = UILabel()
    let descriptionLabel = UILabel()
    let verticalStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

private extension AboutTopTableViewCell {
    private func configure() {
        selectionStyle = .none
        accessoryType = .none
        separatorInset = .zero
        
        contentView.addSubview(verticalStack)

        verticalStack.edges(to: contentView, insets: .horizontal(16) + .vertical(13))
        verticalStack.addArrangedSubview(logoImageView)
        verticalStack.addArrangedSubview(nameLabel)
        verticalStack.addArrangedSubview(descriptionLabel)
        verticalStack.axis = .vertical
        verticalStack.alignment = .center
        verticalStack.distribution = .fill
        verticalStack.spacing = 5

        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.clipsToBounds = true
        logoImageView.layer.cornerRadius = 20
        logoImageView.image = upAnimation
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = R.font.circularStdBold(size: 32)
        nameLabel.textAlignment = .center
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1
        nameLabel.text = appName

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        descriptionLabel.textAlignment = .left
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = "Provenance is a lightweight application that interacts with the Up Banking Developer API to display information about your bank accounts, transactions, categories, tags, and more."
    }
}
