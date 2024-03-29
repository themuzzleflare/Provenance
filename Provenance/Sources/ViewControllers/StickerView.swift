import UIKit
import FLAnimatedImage
import SwiftyBeaver
import TinyConstraints

final class StickerView: ViewController {
    // MARK: - Properties

    private let imageView = FLAnimatedImageView()

    // MARK: - Life Cycle

    init(image: FLAnimatedImage) {
        imageView.animatedImage = image

        super.init(
            nibName: nil,
            bundle: nil
        )

        log.debug("init(image: \(image.description))")

    }

    required init?(coder: NSCoder) { fatalError("Not implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        log.debug("viewDidLoad")

        view.addSubview(imageView)

        configure()
    }
}

// MARK: - Configuration

private extension StickerView {
    private func configure() {
        log.verbose("configure")

        title = "Sticker View"

        navigationItem.title = "Sticker"
        navigationItem.largeTitleDisplayMode = .never

        imageView.centerInSuperview()
        imageView.width(300)
        imageView.height(300)
    }
}
