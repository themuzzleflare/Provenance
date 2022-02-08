import Foundation
import UIKit
import IGListKit
import AsyncDisplayKit

final class DateHeaderModelSC: ListSectionController {
  private var object: DateHeaderModel?

  override func sizeForItem(at index: Int) -> CGSize {
    return ASIGListSectionControllerMethods.sizeForItem(at: index)
  }

  override func cellForItem(at index: Int) -> UICollectionViewCell {
    return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
  }

  override func didUpdate(to object: Any) {
    precondition(object is DateHeaderModel)
    self.object = object as? DateHeaderModel
  }
}

// MARK: - ASSectionController

extension DateHeaderModelSC: ASSectionController {
  func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
    return {
      DateHeaderCellNode(object: self.object!)
    }
  }

  func sizeRangeForItem(at index: Int) -> ASSizeRange {
    return .cellNode(minHeight: 45, maxHeight: 45)
  }
}
