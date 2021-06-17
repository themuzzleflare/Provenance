import UIKit
import TinyConstraints
import Rswift

class CategoryCollectionViewCell: UICollectionViewCell {
    // MARK: - Properties
    
    static let reuseIdentifier = "categoryCollectionViewCell"

    var category: CategoryResource! {
        didSet {
            label.text = category.attributes.name
        }
    }
    
    private let label = UILabel()

    // MARK: - Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCell()
        configureContentView()
        configureLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

// MARK: - Configuration

private extension CategoryCollectionViewCell {
    private func configureCell() {
        clipsToBounds = true
        layer.cornerRadius = 12.5
        layer.borderColor = UIColor.separator.cgColor
        layer.borderWidth = 1.0
        backgroundColor = .secondarySystemGroupedBackground
        selectedBackgroundView = selectedBackgroundCellView
    }
    
    private func configureContentView() {
        contentView.addSubview(label)
    }
    
    private func configureLabel() {
        label.edges(to: contentView, insets: .horizontal(16) + .vertical(13))
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
    }
}
