import IGListKit
import AsyncDisplayKit

final class TransactionsSC: ListSectionController {
  private var object: SortedTransactionModel?
  
  weak var delegate: SelectionDelegate?
  
  init(_ delegate: SelectionDelegate? = nil) {
    self.delegate = delegate
    super.init()
    supplementaryViewSource = self
  }
  
  override func numberOfItems() -> Int {
    return object?.transactions.count ?? 0
  }
  
  override func sizeForItem(at index: Int) -> CGSize {
    return ASIGListSectionControllerMethods.sizeForItem(at: index)
  }
  
  override func cellForItem(at index: Int) -> UICollectionViewCell {
    return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
  }
  
  override func didUpdate(to object: Any) {
    self.object = object as? SortedTransactionModel
  }
  
  override func didSelectItem(at index: Int) {
    collectionContext?.deselectItem(at: index, sectionController: self, animated: true)
    delegate?.didSelectItem(at: IndexPath(item: index, section: section))
  }
  
  override func didDeselectItem(at index: Int) {
    delegate?.didDeselectItem(at: IndexPath(item: index, section: section))
  }
  
  override func didHighlightItem(at index: Int) {
    delegate?.didHighlightItem(at: IndexPath(item: index, section: section))
  }
  
  override func didUnhighlightItem(at index: Int) {
    delegate?.didUnhighlightItem(at: IndexPath(item: index, section: section))
  }
}

  // MARK: - ASSectionController

extension TransactionsSC: ASSectionController {
  func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
    let transaction = object?.transactions[index]
    let node = TransactionCellNode(transaction: transaction)
    return {
      node
    }
  }
  
  func sizeRangeForItem(at index: Int) -> ASSizeRange {
    return .cellNode(minHeight: 55, maxHeight: 85)
  }
}

  // MARK: - ListSupplementaryViewSource

extension TransactionsSC: ListSupplementaryViewSource {
  func supportedElementKinds() -> [String] {
    return [ASCollectionView.elementKindSectionHeader]
  }
  
  func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
    return ASIGListSupplementaryViewSourceMethods.viewForSupplementaryElement(ofKind: elementKind, at: index, sectionController: self)
  }
  
  func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
    return ASIGListSupplementaryViewSourceMethods.sizeForSupplementaryView(ofKind: elementKind, at: index)
  }
}

  // MARK: - ASSupplementaryNodeSource

extension TransactionsSC: ASSupplementaryNodeSource {
  func nodeBlockForSupplementaryElement(ofKind elementKind: String, at index: Int) -> ASCellNodeBlock {
    let node = HeaderCellNode(object: object)
    return {
      node
    }
  }
  
  func sizeRangeForSupplementaryElement(ofKind elementKind: String, at index: Int) -> ASSizeRange {
    return .cellNode(minHeight: 45, maxHeight: 45)
  }
}
