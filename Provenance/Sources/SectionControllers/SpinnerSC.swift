import IGListKit
import AsyncDisplayKit

final class SpinnerSC: ListSectionController {
  override var description: String {
    return "SpinnerSC"
  }
  
  private var object: String?
  
  private weak var loadingDelegate: LoadingDelegate?
  weak var spinnerDelegate: SpinnerDelegate?
  
  init(_ loadingDelegate: LoadingDelegate? = nil) {
    self.loadingDelegate = loadingDelegate
    super.init()
    displayDelegate = self
  }
  
  override func sizeForItem(at index: Int) -> CGSize {
    return ASIGListSectionControllerMethods.sizeForItem(at: index)
  }
  
  override func cellForItem(at index: Int) -> UICollectionViewCell {
    return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
  }
  
  override func didUpdate(to object: Any) {
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

  // MARK: - ListDisplayDelegate

extension SpinnerSC: ListDisplayDelegate {
  func listAdapter(_ listAdapter: ListAdapter, willDisplay sectionController: ListSectionController) {
    return
  }
  
  func listAdapter(_ listAdapter: ListAdapter, didEndDisplaying sectionController: ListSectionController) {
    return
  }
  
  func listAdapter(_ listAdapter: ListAdapter, willDisplay sectionController: ListSectionController, cell: UICollectionViewCell, at index: Int) {
    spinnerDelegate?.startLoading()
    loadingDelegate?.startLoading()
  }
  
  func listAdapter(_ listAdapter: ListAdapter, didEndDisplaying sectionController: ListSectionController, cell: UICollectionViewCell, at index: Int) {
    return
  }
}
