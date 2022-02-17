import Foundation
import UIKit
import IGListKit
import AsyncDisplayKit

final class SpinnerSC: ListSectionController {
  private var object: String?

  weak var spinnerDelegate: SpinnerDelegate?

  override func sizeForItem(at index: Int) -> CGSize {
    return ASIGListSectionControllerMethods.sizeForItem(at: index)
  }

  override func cellForItem(at index: Int) -> UICollectionViewCell {
    return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
  }

  override func didUpdate(to object: Any) {
    precondition(object is String)
    self.object = object as? String
  }
}

// MARK: - ASSectionController

extension SpinnerSC: ASSectionController {
  func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
    return {
      SpinnerCellNode(sectionController: self)
    }
  }

  func sizeRangeForItem(at index: Int) -> ASSizeRange {
    return .cellNode(minHeight: 45, maxHeight: 45)
  }
}
