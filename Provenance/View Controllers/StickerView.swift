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
    
    let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

extension StickerView {
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
