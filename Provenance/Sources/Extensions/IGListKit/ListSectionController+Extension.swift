import IGListKit

extension ListSectionController {
  static func spinnerSectionController() -> ListSingleSectionController {
    let configureBlock = { (_: Any, cell: SpinnerCell) in
      cell.activityIndicator.startAnimating()
    }
    
    let sizeBlock = { (_: Any, context: ListCollectionContext?) -> CGSize in
      guard let context = context else { return .zero }
      return CGSize(width: context.containerSize.width, height: 100)
    }
    
    return ListSingleSectionController(configure: configureBlock, size: sizeBlock)
  }
}
