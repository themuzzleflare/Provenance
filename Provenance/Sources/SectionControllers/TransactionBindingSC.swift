import IGListKit
import SwiftDate

final class TransactionBindingSC: ListBindingSectionController<SortedTransactionModelAlt> {
  override init() {
    super.init()
    dataSource = self
    selectionDelegate = self
    supplementaryViewSource = self
  }
}

  // MARK: - ListBindingSectionControllerDataSource

extension TransactionBindingSC: ListBindingSectionControllerDataSource {
  func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, viewModelsFor object: Any) -> [ListDiffable] {
    guard let object = object as? SortedTransactionModelAlt else { return [] }
    return object.transactions.transactionCellModels
  }
  
  func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, cellForViewModel viewModel: Any, at index: Int) -> UICollectionViewCell & ListBindable {
    switch viewModel {
    case is SortedSectionModel:
      let cell: HeaderCell = collectionContext!.dequeueReusableCell(for: sectionController, at: index)
      return cell
    default:
      let cell: TransactionCollectionCell = collectionContext!.dequeueReusableCell(for: sectionController, at: index)
      return cell
    }
  }
  
  func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, sizeForViewModel viewModel: Any, at index: Int) -> CGSize {
    switch viewModel {
    case is SortedSectionModel:
      return .cellNode(height: 45)
    case is TransactionCellModel:
      return .cellNode(height: 85)
    default:
      return .cellNode(height: 40)
    }
  }
}

  // MARK: - ListBindingSectionControllerSelectionDelegate

extension TransactionBindingSC: ListBindingSectionControllerSelectionDelegate {
  func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, didSelectItemAt index: Int, viewModel: Any) {
    guard let object = object as? SortedTransactionModelAlt, viewModel is TransactionCellModel else { return }
    let transaction = object.transactions[index]
    let controller = TransactionDetailVC(transaction: transaction)
    collectionContext?.deselectItem(at: index, sectionController: sectionController, animated: true)
    viewController?.navigationController?.pushViewController(controller, animated: true)
  }
  
  func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, didDeselectItemAt index: Int, viewModel: Any) {
    return
  }
  
  func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, didHighlightItemAt index: Int, viewModel: Any) {
    return
  }
  
  func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, didUnhighlightItemAt index: Int, viewModel: Any) {
    return
  }
}

  // MARK: - ListSupplementaryViewSource

extension TransactionBindingSC: ListSupplementaryViewSource {
  func supportedElementKinds() -> [String] {
    return [UICollectionView.elementKindSectionHeader]
  }
  
  func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
    let view: HeaderView = collectionContext!.dequeueReusableSupplementaryView(ofKind: elementKind, forSectionController: self, atIndex: index)
    view.dateText = object?.id.toString(.date(.medium))
    return view
  }
  
  func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
    return .cellNode(height: 45)
  }
}
