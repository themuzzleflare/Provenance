import AsyncDisplayKit

final class StickersVC: ASViewController {
  // MARK: - Properties
  
  private let collectionNode = ASCollectionNode(collectionViewLayout: .gridLayout)
  private let stickerGifs = [ASPINRemoteImageDownloader.stickerTwo, ASPINRemoteImageDownloader.stickerThree, ASPINRemoteImageDownloader.stickerSix, ASPINRemoteImageDownloader.stickerSeven]
  
  // MARK: - Life Cycle
  
  override init() {
    super.init(node: collectionNode)
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

private extension StickersVC {
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
    let node = StickerCellNode(sticker: sticker)
    return {
      node
    }
  }
}

// MARK: - ASCollectionDelegate

extension StickersVC: ASCollectionDelegate {
  func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
    let sticker = stickerGifs[indexPath.item]
    let viewController = StickerView(image: sticker)
    navigationController?.pushViewController(viewController, animated: true)
  }
}
