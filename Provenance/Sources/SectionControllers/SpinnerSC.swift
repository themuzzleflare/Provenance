import IGListKit
import AsyncDisplayKit

final class SpinnerSC: ListSectionController {
  private var object: String?
  
  weak var spinnerDelegate: SpinnerDelegate?
  
  override init() {
    super.init()
  }
  
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
    let node = SpinnerCellNode(self)
    return {
      node
    }
  }
  
  func sizeRangeForItem(at index: Int) -> ASSizeRange {
    return .cellNode(minHeight: 45, maxHeight: 45)
  }
}
