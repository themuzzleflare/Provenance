import IGListKit
import AsyncDisplayKit

extension ListCollectionContext {
  func nodeForItem(at index: Int, sectionController: ListSectionController) -> ASCellNode? {
    return (cellForItem(at: index, sectionController: sectionController) as? _ASCollectionViewCell)?.node
  }
}
