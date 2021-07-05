import UIKit
import FLAnimatedImage
import TinyConstraints

final class StickerView: UIViewController {
    // MARK: - Properties
    
    private let imageView = FLAnimatedImageView()

    // MARK: - Life Cycle

    init(image: FLAnimatedImage) {
        imageView.animatedImage = image

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }
}

// MARK: - Configuration

private extension StickerView {
    private func configure() {
        title = "Sticker View"

        view.backgroundColor = .systemGroupedBackground

        navigationItem.title = "Sticker"

        view.addSubview(imageView)

        imageView.centerInSuperview()
        imageView.width(300)
        imageView.height(300)
    }
}
