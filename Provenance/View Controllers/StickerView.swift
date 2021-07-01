import UIKit
import FLAnimatedImage
import TinyConstraints

final class StickerView: UIViewController {
    // MARK: - Properties

    var image: FLAnimatedImage! {
        didSet {
            imageView.animatedImage = image
        }
    }
    
    private let imageView = FLAnimatedImageView()

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }
}

// MARK: - Configuration

private extension StickerView {
    private func configure() {
        title = "Sticker View"

        navigationItem.title = "Sticker"

        view.addSubview(imageView)

        imageView.centerInSuperview()
        imageView.width(300)
        imageView.height(300)
    }
}
