import UIKit
import FLAnimatedImage
import SwiftyBeaver
import TinyConstraints

final class StickerView: UIViewController {
    // MARK: - Properties

    private let imageView = FLAnimatedImageView()

    // MARK: - Life Cycle

    init(image: FLAnimatedImage) {
        imageView.animatedImage = image
        super.init(nibName: nil, bundle: nil)
        log.debug("init(image: \(image.description))")

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        log.debug("viewDidLoad")
        configure()
    }
}

// MARK: - Configuration

private extension StickerView {
    private func configure() {
        log.verbose("configure")

        title = "Sticker View"

        view.backgroundColor = .systemGroupedBackground

        navigationItem.title = "Sticker"
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(imageView)

        imageView.centerInSuperview()
        imageView.width(300)
        imageView.height(300)
    }
}
