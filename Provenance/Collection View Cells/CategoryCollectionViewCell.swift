import UIKit
import TinyConstraints
import Rswift

class CategoryCollectionViewCell: UICollectionViewCell {
    var category: CategoryResource! {
        didSet {
            label.text = category.attributes.name
        }
    }
    
    static let reuseIdentifier = "categoryCollectionViewCell"
    
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureCell()
        configureContentView()
        configureLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CategoryCollectionViewCell {
    private func configureCell() {
        clipsToBounds = true
        layer.cornerRadius = 20
        backgroundColor = .white
        selectedBackgroundView = bgCellView
    }
    
    private func configureContentView() {
        contentView.addSubview(label)
    }
    
    private func configureLabel() {
        label.edges(to: contentView, insets: .horizontal(16) + .vertical(13))
        
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .black
        label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
    }
}
