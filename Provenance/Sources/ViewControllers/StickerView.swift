import AsyncDisplayKit

final class StickerView: ASViewController {
  // MARK: - Life Cycle

  init(image: ASAnimatedImageProtocol) {
    super.init(node: StickerImageNode(sticker: image))
  }

  deinit {
    print("deinit")
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

private extension StickerView {
  private func configureSelf() {
    title = "Sticker View"
  }

  private func configureNavigation() {
    navigationItem.title = "Sticker"
    navigationItem.largeTitleDisplayMode = .never
  }
}
