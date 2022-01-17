import Foundation
import UIKit
import IGListKit
import IGListSwiftKit
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
      return collectionContext.dequeueReusableCell(for: self, at: index) as HeaderCell
    case is TransactionCellModel:
      return collectionContext.dequeueReusableCell(for: self, at: index) as TransactionCell
    default:
      fatalError("Unknown view model")
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
    guard let object = object, viewModel is TransactionCellModel else { return }
    let transaction = object.transactions[index]
    let controller = TransactionDetailVC(transaction: transaction)
    collectionContext.deselectItem(at: index, sectionController: sectionController, animated: true)
    viewController?.navigationController?.pushViewController(controller, animated: true)
  }

  func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, didDeselectItemAt index: Int, viewModel: Any) {}

  func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, didHighlightItemAt index: Int, viewModel: Any) {}

  func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, didUnhighlightItemAt index: Int, viewModel: Any) {}
}

// MARK: - ListSupplementaryViewSource

extension TransactionBindingSC: ListSupplementaryViewSource {
  func supportedElementKinds() -> [String] {
    return [UICollectionView.elementKindSectionHeader]
  }

  func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
    let view = collectionContext.dequeueReusableSupplementaryView(ofKind: elementKind, forSectionController: self, atIndex: index) as HeaderView
    view.dateText = object?.id.toString(.date(.medium))
    return view
  }

  func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
    return .cellNode(height: 45)
  }
}
