import UIKit

final class TagCollectionViewListCell: UICollectionViewListCell {
    static let reuseIdentifier = "tagCollectionViewListCell"

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
