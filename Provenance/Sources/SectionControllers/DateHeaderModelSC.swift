import Foundation
import UIKit
import IGListKit
import AsyncDisplayKit

final class DateHeaderModelSC: ListSectionController {
  private var object: DateHeaderModel!

  private weak var selectionDelegate: SelectionDelegate?

  init(selectionDelegate: SelectionDelegate? = nil) {
    self.selectionDelegate = selectionDelegate
  }

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

  override func didSelectItem(at index: Int) {
    selectionDelegate?.didSelectItem(at: IndexPath(item: index, section: section), with: object.id.description)
  }

  override func didDeselectItem(at index: Int) {
    selectionDelegate?.didDeselectItem(at: IndexPath(item: index, section: section))
  }

  override func didHighlightItem(at index: Int) {
    selectionDelegate?.didHighlightItem(at: IndexPath(item: index, section: section))
  }

  override func didUnhighlightItem(at index: Int) {
    selectionDelegate?.didUnhighlightItem(at: IndexPath(item: index, section: section))
  }
}

// MARK: - ASSectionController

extension DateHeaderModelSC: ASSectionController {
  func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
    return {
      DateHeaderCellNode(model: self.object)
    }
  }

  func sizeRangeForItem(at index: Int) -> ASSizeRange {
    return .cellNode(minHeight: 45, maxHeight: 45)
  }
}
