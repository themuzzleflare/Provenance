import UIKit
import AsyncDisplayKit

final class StickersVC: ASViewController {
  // MARK: - Properties

  private let collectionNode = ASCollectionNode(collectionViewLayout: .grid)
  private let stickers: [AnimatedImage] = [.stickerTwo, .stickerThree, .stickerSix, .stickerSeven]

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
    return stickers.count
  }

  func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
    let sticker = stickers[indexPath.item]
    return {
      StickerCellNode(sticker: sticker)
    }
  }
}

// MARK: - ASCollectionDelegate

extension StickersVC: ASCollectionDelegate {
  func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
    let sticker = stickers[indexPath.item]
    let viewController = StickerVC(sticker: sticker)
    navigationController?.pushViewController(viewController, animated: true)
  }
}
