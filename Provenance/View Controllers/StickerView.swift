import UIKit
import SwiftyGif
import TinyConstraints

class StickerView: ViewController {
    // MARK: - Properties

    var image: UIImage! {
        didSet {
            imageView.setGifImage(image)
            imageView.startAnimatingGif()
        }
    }
    
    private let imageView = UIImageView()

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
        imageView.width(300)
        imageView.height(300)
        imageView.centerInSuperview()
        imageView.frame = view.bounds
    }
}
