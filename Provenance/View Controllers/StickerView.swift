import UIKit
import SwiftyGif
import TinyConstraints

class StickerView: ViewController {
    var image: UIImage! {
        didSet {
            imageView.setGifImage(image)
            imageView.startAnimatingGif()
        }
    }
    
    private let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

private extension StickerView {
    private func configure() {
        title = "Sticker View"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "Sticker"
        view.addSubview(imageView)
        imageView.width(300)
        imageView.height(300)
        imageView.centerInSuperview()
        imageView.frame = view.bounds
    }
}
