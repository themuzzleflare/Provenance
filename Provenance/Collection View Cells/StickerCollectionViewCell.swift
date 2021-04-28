import UIKit
import SwiftyGif
import TinyConstraints

class StickerCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "stickerCollectionViewCell"
    
    var image: UIImage! {
        didSet {
            stickerImageView.setGifImage(image)
            stickerImageView.startAnimatingGif()
        }
    }
    
    let stickerImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

private extension StickerCollectionViewCell {
    private func configure() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.cgColor
        
        contentView.addSubview(stickerImageView)
        
        stickerImageView.edges(to: contentView)
        stickerImageView.frame = contentView.bounds
    }
}
