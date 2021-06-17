import UIKit
import FLAnimatedImage
import TinyConstraints

class StickerView: ViewController {
    // MARK: - Properties

    var image: FLAnimatedImage! {
        didSet {
            imageView.animatedImage = image
            imageView.startAnimating()
        }
    }
    
    private let imageView = FLAnimatedImageView()

    // MARK: - View Life Cycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

// MARK: - Configuration

private extension StickerView {
    private func configure() {
        title = "Sticker View"
        navigationItem.title = "Sticker"
        view.addSubview(imageView)
        imageView.width(300)
        imageView.height(300)
        imageView.centerInSuperview()
    }
}
