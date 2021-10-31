import AsyncDisplayKit

final class StickersVC: ASViewController {
  // MARK: - Properties

  private let collectionNode = ASCollectionNode(collectionViewLayout: .grid)
  private let stickerGifs: [AnimatedImage] = [.stickerTwo, .stickerThree, .stickerSix, .stickerSeven]

  // MARK: - Life Cycle

  override init() {
    super.init(node: collectionNode)
  }

  deinit {
    print("\(#function) \(String(describing: type(of: self)))")
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureSelf()
    configureNavigation()
    configureCollectionNode()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    collectionNode.reloadData()
  }
}

// MARK: - Configuration

extension StickersVC {
  private func configureSelf() {
    title = "Stickers"
  }

  private func configureNavigation() {
    navigationItem.title = "Stickers"
    navigationItem.largeTitleDisplayMode = .never
  }

  private func configureCollectionNode() {
    collectionNode.dataSource = self
    collectionNode.delegate = self
  }
}

// MARK: - ASCollectionDataSource

extension StickersVC: ASCollectionDataSource {
  func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
    return stickerGifs.count
  }

  func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
    let sticker = stickerGifs[indexPath.item]
    let node = StickerCellNode(sticker: sticker.asAnimatedImage)
    return {
      node
    }
  }
}

// MARK: - ASCollectionDelegate

extension StickersVC: ASCollectionDelegate {
  func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
    let sticker = stickerGifs[indexPath.item]
    let viewController = StickerView(image: sticker.asAnimatedImage)
    navigationController?.pushViewController(viewController, animated: true)
  }
}
