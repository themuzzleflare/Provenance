import UIKit
import TinyConstraints
import Rswift

final class AttributeCollectionViewCell: UICollectionViewCell {
    // MARK: - Properties

    static let reuseIdentifier = "attributeCollectionViewCell"

    var leftLabel = UILabel()
    var rightLabel = UILabel()

    private let horizontalStack = UIStackView()
    private let insets: UIEdgeInsets = .zero
    private let separator: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.separator.cgColor
        return layer
    }()

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureCell()
        configureContentView()
        configureLeftLabel()
        configureRightLabel()
        configureHorizontalStackView()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        horizontalStack.frame = contentView.bounds.inset(by: insets)
        separator.frame = CGRect(x: insets.left, y: contentView.bounds.height - 0.5, width: contentView.bounds.width - insets.left, height: 0.5)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        separator.backgroundColor = UIColor.separator.cgColor
    }
}

// MARK: - Configuration

private extension AttributeCollectionViewCell {
    private func configureCell() {
        selectedBackgroundView = selectedBackgroundCellView
        backgroundColor = .clear
    }

    private func configureContentView() {
        contentView.addSubview(horizontalStack)
        contentView.layer.addSublayer(separator)
    }

    private func configureLeftLabel() {
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        leftLabel.font = R.font.circularStdMedium(size: UIFont.labelFontSize)
        leftLabel.textAlignment = .left
        leftLabel.textColor = .secondaryLabel
        leftLabel.numberOfLines = 0
    }

    private func configureRightLabel() {
        rightLabel.translatesAutoresizingMaskIntoConstraints = false
        rightLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        rightLabel.textAlignment = .right
        rightLabel.numberOfLines = 0
    }
    
    private func configureHorizontalStackView() {
        horizontalStack.edgesToSuperview(insets: .horizontal(16) + .vertical(13))
        horizontalStack.addArrangedSubview(leftLabel)
        horizontalStack.addArrangedSubview(rightLabel)
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
    }
}
