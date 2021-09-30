import IGListKit
import AsyncDisplayKit

final class ItemModelSC: ListSectionController {
  override var description: String {
    return "ItemModelSC"
  }
  
  private var object: TransactionCellModel?
  
  weak var selectionDelegate: SelectionDelegate?
  
  init(_ selectionDelegate: SelectionDelegate? = nil) {
    self.selectionDelegate = selectionDelegate
    super.init()
    supplementaryViewSource = self
  }
  
  override func sizeForItem(at index: Int) -> CGSize {
    return ASIGListSectionControllerMethods.sizeForItem(at: index)
  }
  
  override func cellForItem(at index: Int) -> UICollectionViewCell {
    return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
  }
  
  override func didUpdate(to object: Any) {
    self.object = object as? TransactionCellModel
  }
  
  override func didSelectItem(at index: Int) {
    collectionContext?.deselectItem(at: index, sectionController: self, animated: true)
    selectionDelegate?.didSelectItem(at: IndexPath(item: index, section: section))
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

extension ItemModelSC: ASSectionController {
  func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
    let node = TransactionCellNode(transaction: object)
    return {
      node
    }
  }
  
  func sizeRangeForItem(at index: Int) -> ASSizeRange {
    return .cellNode(minHeight: 55, maxHeight: 85)
  }
}

  // MARK: - ListSupplementaryViewSource

extension ItemModelSC: ListSupplementaryViewSource {
  func supportedElementKinds() -> [String] {
    return [ASCollectionView.elementKindSectionFooter]
  }
  
  func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
    return ASIGListSupplementaryViewSourceMethods.viewForSupplementaryElement(ofKind: elementKind, at: index, sectionController: self)
  }
  
  func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
    return ASIGListSupplementaryViewSourceMethods.sizeForSupplementaryView(ofKind: elementKind, at: index)
  }
}

  // MARK: - ASSupplementaryNodeSource

extension ItemModelSC: ASSupplementaryNodeSource {
  func nodeBlockForSupplementaryElement(ofKind elementKind: String, at index: Int) -> ASCellNodeBlock {
    let node = SeparatorCellNode()
    return {
      node
    }
  }
  
  func sizeRangeForSupplementaryElement(ofKind elementKind: String, at index: Int) -> ASSizeRange {
    return .separator
  }
}
