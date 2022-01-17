import Foundation
import UIKit
import IGListKit
import AsyncDisplayKit

final class TagSectionModelSC: ListSectionController {
  private var object: SortedTagSectionModel?

  override func sizeForItem(at index: Int) -> CGSize {
    return ASIGListSectionControllerMethods.sizeForItem(at: index)
  }

  override func cellForItem(at index: Int) -> UICollectionViewCell {
    return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
  }

  override func didUpdate(to object: Any) {
    precondition(object is SortedTagSectionModel)
    self.object = object as? SortedTagSectionModel
  }
}

// MARK: - ASSectionController

extension TagSectionModelSC: ASSectionController {
  func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
    let node = HeaderCellNode(object: object)
    return {
      node
    }
  }

  func sizeRangeForItem(at index: Int) -> ASSizeRange {
    return .cellNode(minHeight: 45, maxHeight: 45)
  }
}
