import UIKit
import AsyncDisplayKit
import PINRemoteImage

final class StickerView: ASViewController {
    // MARK: - Life Cycle
  
  init(image: ASAnimatedImageProtocol) {
    super.init(node: StickerImageNode(sticker: image))
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
    navigationItem.title = "Sticker"
    navigationItem.largeTitleDisplayMode = .never
  }
}
