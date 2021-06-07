import UIKit
import FLAnimatedImage
import TinyConstraints

class StickerCollectionViewCell: UICollectionViewCell {
    // MARK: - Properties
    
    static let reuseIdentifier = "stickerCollectionViewCell"
    
    var image: FLAnimatedImage! {
        didSet {
            stickerImageView.animatedImage = image
            stickerImageView.startAnimating()
        }
    }
    
    private let stickerImageView = FLAnimatedImageView()

    // MARK: - Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

// MARK: - Configuration

private extension StickerCollectionViewCell {
    private func configure() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.separator.cgColor
        contentView.addSubview(stickerImageView)
        stickerImageView.edges(to: contentView)
    }
}
