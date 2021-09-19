import UIKit
import AsyncDisplayKit
import PINRemoteImage

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
    configure()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    collectionNode.reloadData()
  }
}

// MARK: - Configuration

private extension StickersVC {
  private func configure() {
    title = "Stickers"
    navigationItem.title = "Stickers"
    navigationItem.largeTitleDisplayMode = .never
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
    let node = StickerCellNode(sticker: stickerGifs[indexPath.item])
    return {
      node
    }
  }
}

// MARK: - ASCollectionDelegate

extension StickersVC: ASCollectionDelegate {
  func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
    let image = stickerGifs[indexPath.item]
    navigationController?.pushViewController(StickerView(image: image), animated: true)
  }
}
