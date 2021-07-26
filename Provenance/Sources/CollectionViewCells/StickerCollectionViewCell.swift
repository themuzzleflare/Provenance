import UIKit
import FLAnimatedImage

final class StickerCollectionViewCell: UICollectionViewCell {
    // MARK: - Properties

    static let reuseIdentifier = "stickerCollectionViewCell"

    var image: FLAnimatedImage! {
        didSet {
            stickerImageView.animatedImage = image
        }
    }

    private let stickerImageView = FLAnimatedImageView()

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        configure()
    }

    required init?(coder: NSCoder) { fatalError("Not implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        stickerImageView.frame = contentView.bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        layer.borderColor = UIColor.separator.cgColor
    }
}

// MARK: - Configuration

private extension StickerCollectionViewCell {
    private func configure() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.separator.cgColor
        contentView.addSubview(stickerImageView)
    }
}
