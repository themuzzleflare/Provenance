import IGListKit
import AsyncDisplayKit

final class SectionModelSC: ListSectionController {
  private var object: SortedSectionModel?

  override func sizeForItem(at index: Int) -> CGSize {
    return ASIGListSectionControllerMethods.sizeForItem(at: index)
  }

  override func cellForItem(at index: Int) -> UICollectionViewCell {
    return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
  }

  override func didUpdate(to object: Any) {
    precondition(object is SortedSectionModel)
    self.object = object as? SortedSectionModel
  }
}

// MARK: - ASSectionController

extension SectionModelSC: ASSectionController {
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
