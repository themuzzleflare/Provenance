import UIKit
import TinyConstraints
import Rswift

final class AttributeTableViewCell: UITableViewCell {
    // MARK: - Properties

    static let reuseIdentifier = "attributeTableViewCell"

    var leftLabel = UILabel()
    
    var rightLabel = SRCopyableLabel()

    private let horizontalStack = UIStackView()

    // MARK: - Life Cycle
    
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

// MARK: - Configuration

private extension AttributeTableViewCell {
    private func configureCell() {
        selectionStyle = .none
        selectedBackgroundView = selectedBackgroundCellView
    }
    
    private func configureContentView() {
        contentView.addSubview(horizontalStack)
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
