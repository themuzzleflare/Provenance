import UIKit
import AsyncDisplayKit

final class StickerVC: ASViewController {
  // MARK: - Properties

  private var sticker: AnimatedImage

  // MARK: - Life Cycle

  init(sticker: AnimatedImage) {
    self.sticker = sticker
    super.init(node: StickerDisplayNode(sticker: sticker))
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureSelf()
    configureNavigation()
  }
}

// MARK: - Configuration

extension StickerVC {
  private func configureSelf() {
    title = "Sticker View"
  }

  private func configureNavigation() {
    navigationItem.title = "Sticker"
    navigationItem.largeTitleDisplayMode = .never
  }
}
